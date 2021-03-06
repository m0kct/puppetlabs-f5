Puppet::Type.newtype(:f5_external_class) do
  @doc = "Manages F5 External classes (datagroups)"

  apply_to_device

  ensurable do
    desc "F5 External Class resource state. Valid values are present, absent."

    defaultto(:present)

    newvalue(:present) do
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end
  end

  newparam(:name, :namevar=>true) do
    desc "The external class name."
  end

  newproperty(:file_format) do
    desc "The file format for the specified classes. This should only be called
    for external classes, since it does not make sense for non-external classes."

    newvalues(/^FILE_FORMAT_(UNKNOWN|CSV)$/)
    defaultto('FILE_FORMAT_CSV')
  end

  newproperty(:file_mode) do
    desc "The file modes for the specified classes. This should only be called
    for external classes, since it does not make sense for non-external classes."

    newvalues(/^FILE_MODE_(UNKNOWN|TYPE_READ|TYPE_READ_WRITE)$/)
    defaultto('FILE_MODE_TYPE_READ_WRITE')
  end

  newproperty(:file_name) do
    desc "The file names for the specified classes. This should only be called
    for external classes, since it does not make sense for non-external classes."

    validate do |value|
      raise Puppet::Error, "Puppet::Type::F5_external_class: file_name must be absolute path." unless value = File.expand_path(value)
    end
  end

  newproperty(:data_separator) do
    desc "The class types for the specified classes."

    newvalues(/^[[:punct:][:space:]]+$/)
    defaultto(':=')
  end

  newproperty(:type) do
    desc "The class types for the specified classes."

    newvalues(/^CLASS_TYPE_(UNDEFINED|ADDRESS|STRING|VALUE)$/)
  end

  # auto require f5_file.
  autorequire(:f5_file) do
    if f5_file = self[:file_name]
      f5_file
    end
  end
end
