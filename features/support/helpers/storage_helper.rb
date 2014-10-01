# Helper class for manipulating VM storage *volumes*, i.e. it deals
# only with creation of images and keeps a name => volume path lookup
# table (plugging drives or getting info of plugged devices is done in
# the VM class). We'd like better coupling, but given the ridiculous
# disconnect between Libvirt::StoragePool and Libvirt::Domain (hint:
# they have nothing with each other to do whatsoever) it's what makes
# sense.

require 'libvirt'
require 'rexml/document'
require 'etc'

class VMStorage

  @@virt = nil

  def initialize(virt, xml_path)
    @@virt ||= virt
    @xml_path = xml_path
    pool_xml = REXML::Document.new(File.read("#{@xml_path}/storage_pool.xml"))
    pool_name = pool_xml.elements['pool/name'].text
    begin
      @pool = @@virt.lookup_storage_pool_by_name(pool_name)
    rescue Libvirt::RetrieveError
      # There's no pool with that name, so we don't have to clear it
    else
      VMStorage.clear_storage_pool(@pool)
    end
    @pool_path = "#{$tmp_dir}/#{pool_name}"
    pool_xml.elements['pool/target/path'].text = @pool_path
    @pool = @@virt.define_storage_pool_xml(pool_xml.to_s)
    @pool.build
    @pool.create
    @pool.refresh
  end

  def VMStorage.clear_storage_pool_volumes(pool)
    was_not_active = !pool.active?
    if was_not_active
      pool.create
    end
    pool.list_volumes.each do |vol_name|
      vol = pool.lookup_volume_by_name(vol_name)
      vol.delete
    end
    if was_not_active
      pool.destroy
    end
  rescue
    # Some of the above operations can fail if the pool's path was
    # deleted by external means; let's ignore that.
  end

  def VMStorage.clear_storage_pool(pool)
    VMStorage.clear_storage_pool_volumes(pool)
    pool.destroy if pool.active?
    pool.undefine
  end

  def clear_pool
    VMStorage.clear_storage_pool(@pool)
  end

  def clear_volumes
    VMStorage.clear_storage_pool_volumes(@pool)
  end

  def create_new_disk(name, options = {})
    options[:size] ||= 2
    options[:unit] ||= "GiB"
    options[:type] ||= "qcow2"
    begin
      old_vol = @pool.lookup_volume_by_name(name)
    rescue Libvirt::RetrieveError
      # noop
    else
      old_vol.delete
    end
    uid = Etc::getpwnam("libvirt-qemu").uid
    gid = Etc::getgrnam("libvirt-qemu").gid
    vol_xml = REXML::Document.new(File.read("#{@xml_path}/volume.xml"))
    vol_xml.elements['volume/name'].text = name
    size_b = convert_to_bytes(options[:size].to_f, options[:unit])
    vol_xml.elements['volume/capacity'].text = size_b.to_s
    vol_xml.elements['volume/target/format'].attributes["type"] = options[:type]
    vol_xml.elements['volume/target/path'].text = "#{@pool_path}/#{name}"
    vol_xml.elements['volume/target/permissions/owner'].text = uid.to_s
    vol_xml.elements['volume/target/permissions/group'].text = gid.to_s
    vol = @pool.create_volume_xml(vol_xml.to_s)
    @pool.refresh
  end

  def clone_to_new_disk(from, to)
    begin
      old_to_vol = @pool.lookup_volume_by_name(to)
    rescue Libvirt::RetrieveError
      # noop
    else
      old_to_vol.delete
    end
    from_vol = @pool.lookup_volume_by_name(from)
    xml = REXML::Document.new(from_vol.xml_desc)
    pool_path = REXML::Document.new(@pool.xml_desc).elements['pool/target/path'].text
    xml.elements['volume/name'].text = to
    xml.elements['volume/target/path'].text = "#{pool_path}/#{to}"
    @pool.create_volume_xml_from(xml.to_s, from_vol)
  end

  def disk_format(name)
    vol = @pool.lookup_volume_by_name(name)
    vol_xml = REXML::Document.new(vol.xml_desc)
    return vol_xml.elements['volume/target/format'].attributes["type"]
  end

  def disk_path(name)
    @pool.lookup_volume_by_name(name).path
  end

  # We use parted for the disk_mk* functions since it can format
  # partitions "inside" the super block device; mkfs.* need a
  # partition device (think /dev/sdaX), so we'd have to use something
  # like losetup or kpartx, which would require administrative
  # privileges. These functions only work for raw disk images.

  # TODO: We should switch to guestfish/libguestfs (which has
  # ruby-bindings) so we could use qcow2 instead of raw, and more
  # easily use LVM volumes.

  # For type, see label-type for mklabel in parted(8)
  def disk_mklabel(name, type)
    assert_equal("raw", disk_format(name))
    path = disk_path(name)
    cmd_helper("/sbin/parted -s '#{path}' mklabel #{type}")
  end

  # For fstype, see fs-type for mkfs in parted(8)
  def disk_mkpartfs(name, fstype)
    assert(disk_format(name), "raw")
    path = disk_path(name)
    cmd_helper("/sbin/parted -s '#{path}' mkpartfs primary '#{fstype}' 0% 100%")
  end

end
