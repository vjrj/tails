/* hugetlb_mem_wipe.c: zero memory using Linux hugetlb
 * Copyright (C) 2012 Tails developers <tails@boum.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/* Design:
 *
 * Memory wipe is done on memory areas allocated using mmap(). When the
 * memory is to be filled with zeros, it relies on the combination of
 * MAP_ANONYMOUS | MAP_POPULATE | MAP_SHARED flags which makes the kernel
 * clear the memory. Otherwise, it uses memset() on the allocated area.
 *
 * First, pages are allocated using MAP_HUGETLB. Once all huge pages are
 * allocated, we continue the process using "usual" page size until we have
 * taken care of the amount of memory given on the command line.
 *
 * A new process is spawned after one process has wiped 1 GB in order to
 * overcome the limit of maximum memory addressable by a single process
 * on 32-bit architectures.
 *
 * The progress bar boundaries are given using command-line arguments:
 *
 *     hugetlb_mem_wipe WIPED_KB TOTAL_KB
 */

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define PAGE_SIZE 0x1000 /* 4 kB on x86 */
#define HUGE_PAGE_SIZE 0x200000 /* 2 MB on x86 PAE */
#define PROGRESS_FREQUENCY 1024 /* 1 MB (should be below HUGE_PAGE_SIZE) */
#define ZERO_PATTERN 0

#define LINE_SIZE 74
#define PROGRESS_SIZE (LINE_SIZE - 7)

void __attribute__((noreturn)) usage_and_exit(void)
{
    fprintf(stderr, "Usage: hugetlb_mem_wipe WIPE_MEM_KB TOTAL_MEM_KB\n");
    exit(1);
}

/* taken from command line */
static unsigned long total_mem_kb = 0;
/* taken from command line, incremented in zero_area() */
static unsigned long wiped_mem_kb = 0;

int read_arg(char const * arg, unsigned long int * value)
{
    char * endptr;

    *value = strtoul(arg, &endptr, 10);
    if ('\0' != *endptr) {
        usage_and_exit();
    }
    if (ERANGE == errno) {
        return 1;
    }
    return 0;
}

static void show_progress(void)
{
    unsigned short i;

    putchar('[');
    for (i = 0; i <= (PROGRESS_SIZE * wiped_mem_kb / total_mem_kb); i++) {
        putchar('=');
    }
    putchar('>');
    for (; i <= PROGRESS_SIZE; i++) {
        putchar(' ');
    }
    printf("] %3lu%%\r", 100 * wiped_mem_kb / total_mem_kb);
    fflush(stdout);
}

static void zero_area(void * s, size_t length)
{
    size_t pos;
    size_t chunk_size;

    pos = 0;
    while (length > pos) {
        chunk_size = PROGRESS_FREQUENCY * 1024;
        if (length - pos < chunk_size) {
            chunk_size = length - pos;
        }
        memset(s + pos, ZERO_PATTERN, chunk_size);
        pos += chunk_size;
        wiped_mem_kb += chunk_size / 1024;
        show_progress();
    }
}

static int wipe_page(int use_huge)
{
    unsigned char * page;
    size_t size = use_huge ? HUGE_PAGE_SIZE : (PAGE_SIZE * 8);
    size_t const max_kb = total_mem_kb - wiped_mem_kb;

    if (size / 1024 > max_kb) {
        size = max_kb * 1024;
    }
    page = mmap(NULL /* map anywhere */,
                size, PROT_READ | PROT_WRITE,
                MAP_ANONYMOUS |
                /* watch out: MAP_POPULATE only works with MAP_SHARED! */
                MAP_POPULATE | MAP_SHARED |
                (use_huge ? MAP_HUGETLB : 0),
                -1 /* ignored */, 0 /* ignored */);
    if (MAP_FAILED == page) {
        return 1;
    }
    /* If we want to fill the memory with zeros, MAP_POPULATE has already taken
     * care of it. */
    if (0 == ZERO_PATTERN) {
        wiped_mem_kb += size / 1024;
        show_progress();
    } else {
        zero_area(page, size);
    }
    return 0;
}

#define MEM_KB_STR_SIZE 11
static int spawn_new(void)
{
    pid_t pid;
    char wiped_mem_kb_str[MEM_KB_STR_SIZE];
    char total_mem_kb_str[MEM_KB_STR_SIZE];
    int status;

    if (0 == (pid = fork())) {
        snprintf(wiped_mem_kb_str, MEM_KB_STR_SIZE, "%lu",
                 wiped_mem_kb);
        snprintf(total_mem_kb_str, MEM_KB_STR_SIZE, "%lu",
                 total_mem_kb);
        execl("/proc/self/exe", "hugetlb_mem_wipe", wiped_mem_kb_str,
              total_mem_kb_str, NULL);
        /* if reached, something wrong happened */
        perror("execl");
        return 1;
    }
    waitpid(pid, &status, 0 /* default options */);
    if (WIFEXITED(status)) {
        return WEXITSTATUS(status);
    }
    return -1;
}

static int do_wipe(void)
{
    int ret;
    int use_huge = 1;
    unsigned long start_wiped_mem_kb = wiped_mem_kb;

    while (wiped_mem_kb < total_mem_kb) {
        if (0 != wipe_page(use_huge)) {
            if (ENOMEM == errno && use_huge) {
                /* switch to small pages */
                use_huge = 0;
                continue;
            }
            perror("wipe_page");
            return 1;
        }
        if (wiped_mem_kb - start_wiped_mem_kb > (1024 * 1024) /* 1 GB */) {
            if (0 != (ret = spawn_new())) {
                fprintf(stderr, "spawn_new failed (%d)\n", ret);
                return 1;
            }
            break;
        }
    }
    return 0;
}

int main(int argc, char ** argv)
{
    int ret;

    if (0 != read_arg(argv[1], &wiped_mem_kb)) {
        fprintf(stderr, "wiped_mem_kb is too big.\n");
    }
    if (0 != read_arg(argv[2], &total_mem_kb)) {
        fprintf(stderr, "total_mem_kb is too big.\n");
    }
    ret = do_wipe();
    return ret;
}
