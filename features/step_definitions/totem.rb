def shared_video_dir_on_guest
  "/tmp/shared_video_dir"
end

Given /^I create sample videos$/ do
  next if @skip_steps_while_restoring_background
  fatal_system("ffmpeg -loop 1 -t 30 -f image2 " +
               "-i 'features/images/TailsBootSplash.png' " +
               "-an -vcodec libx264 -y " +
               "'#{$misc_files_dir}/video.mp4' >/dev/null 2>&1")
end

Given /^I setup a filesystem share containing sample videos$/ do
  next if @skip_steps_while_restoring_background
  @vm.add_share($misc_files_dir, shared_video_dir_on_guest)
end

Given /^I copy the sample videos to "([^"]+)" as user "([^"]+)"$/ do |destination, user|
  next if @skip_steps_while_restoring_background
  for video_on_host in Dir.glob("#{$misc_files_dir}/*.mp4") do
    video_name = File.basename(video_on_host)
    src_on_guest = "#{shared_video_dir_on_guest}/#{video_name}"
    dst_on_guest = "#{destination}/#{video_name}"
    step "I copy \"#{src_on_guest}\" to \"#{dst_on_guest}\" as user \"amnesia\""
  end
end

When /^I start Totem through the GNOME menu$/ do
  next if @skip_steps_while_restoring_background
  @screen.wait_and_click("GnomeApplicationsMenu.png", 10)
  @screen.wait_and_click("GnomeApplicationsSoundVideo.png", 10)
  @screen.wait_and_click("GnomeApplicationsTotem.png", 20)
  @screen.wait_and_click("TotemMainWindow.png", 20)
end

When /^I load the "([^"]+)" URL in Totem$/ do |url|
  next if @skip_steps_while_restoring_background
  @screen.type("l", Sikuli::KeyModifier.CTRL)
  @screen.wait("TotemOpenUrlDialog.png", 10)
  @screen.type(url + Sikuli::Key.ENTER)
end

When /^I(?:| try to) open "([^"]+)" with Totem$/ do |filename|
  next if @skip_steps_while_restoring_background
  step "I run \"totem #{filename}\" in GNOME Terminal"
end

When /^I close Totem$/ do
  step 'I kill the process "totem"'
end
