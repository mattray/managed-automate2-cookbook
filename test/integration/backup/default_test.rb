# internal backup dir
describe directory('/var/opt/chef-automate/backups') do
  it { should exist }
end

# external backup dir
describe directory('/tmp/test/backups') do
  it { should exist }
end

describe file('/var/opt/chef-automate/backups/automate-backup.sh') do
  its('content') { should match(%r{^#!/bin/sh$}) }
  its('content') { should match(%r{^cd /var/opt/chef-automate/backups$}) }
  its('content') { should match(%r{^/bin/chef-automate backup create --result-json backup-result.json >> backup.log 2>&1$}) }
  its('content') { should match(%r{^tar -czf /tmp/test/backups/automate-backup-\${backup_id}.tgz backup-result.json automate-elasticsearch-data \$backup_id -C /tmp/kitchen/cache automate-credentials.toml$}) }
  its('content') { should match(/^rm -rf \$backup_id$/) }
end

# add crontab entry for cron[chef-automate backup create]
describe crontab do
  its('commands') { should include '/var/opt/chef-automate/backups/automate-backup.sh' }
end

describe crontab.commands('/var/opt/chef-automate/backups/automate-backup.sh') do
  its('minutes') { should cmp '*/5' }
  its('hours') { should cmp '*' }
  its('days') { should cmp '*' }
  its('months') { should cmp '*' }
  its('weekdays') { should cmp '*' }
end

describe command('chef-automate config show') do
  its('stdout') { should match /\[global\.v1\.backups\]$/ }
  its('stdout') { should match /\[global\.v1\.backups\.filesystem\]$/ }
  its('stdout') { should match /path = \"\/var\/opt\/chef-automate\/backups\"$/ }
end
