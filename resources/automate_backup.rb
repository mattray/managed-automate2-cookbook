resource_name :automate_backup
provides :automate_backup

property :backup_directory, String, default: '/var/opt/chef-automate/backups'
property :export_directory, String
property :export_prefix, String
property :minute, String, default: '*'
property :hour, String, default: '*'
property :day, String, default: '*'
property :month, String, default: '*'
property :weekday, String, default: '*'
# property :count, Integer

# https://automate.chef.io/docs/backup
# schedule backups via cron
action :schedule do
  backup_directory = new_resource.backup_directory
  export_directory = new_resource.export_directory
  fcp = Chef::Config[:file_cache_path]

  # Configure A2 internal backups
  backupconfig = fcp + '/backup_config.toml'

  config = { 'global.v1.backups.filesystem': { 'path': backup_directory } }

  toml_file backupconfig do
    content config
  end

  directory backup_directory

  execute "chef-automate config patch #{backupconfig}" do
    action :nothing
    subscribes :run, "toml_file[#{backupconfig}]"
  end

  command = "#!/bin/sh
cd #{backup_directory}
/bin/chef-automate backup create --result-json backup-result.json >> backup.log 2>&1
"

  # Configure external backup storage
  if export_directory
    export_prefix = new_resource.export_prefix

    directory export_directory

    # credentials from the original location or from a restored backup
    tar = if ::File.exist?(fcp + '/automate-credentials.toml')
            "tar -czf #{export_directory}/#{export_prefix}${backup_id}.tgz backup-result.json automate-elasticsearch-data $backup_id -C #{fcp} automate-credentials.toml"
          elsif ::File.exist?(backup_directory + '/automate-credentials.toml')
            "tar -czf #{export_directory}/#{export_prefix}${backup_id}.tgz backup-result.json automate-elasticsearch-data $backup_id -C #{backup_directory} automate-credentials.toml"
          else
            "tar -czf #{export_directory}/#{export_prefix}${backup_id}.tgz backup-result.json automate-elasticsearch-data $backup_id"
          end

    command += "backup_id=`sed 's/.*backup_id\":\"\\([0-9]*\\).*/\\1/g' backup-result.json`
#{tar}
rm -rf $backup_id
"
  end

  # Schedule regular backups & copy via cron
  file backup_directory + '/automate-backup.sh' do
    mode '0700'
    content command
  end

  # schedule backup on a recurring cron job. Override attributes as necessary
  cron 'chef-automate backup create' do
    command backup_directory + '/automate-backup.sh'
    minute new_resource.minute
    hour new_resource.hour
    day new_resource.day
    month new_resource.month
    weekday new_resource.weekday
  end
end

# delete a backup
# action :delete do
# chef-automate backup list
#   # keep track of the count for the directory
# end
