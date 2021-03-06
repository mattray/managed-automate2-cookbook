fcpchef = attribute('fcpchef', default: '/root/chef-automate')
fcpfile = attribute('fcpfile', default: '/root/chef-automate.aib')
aibchef = attribute('aibchef', default: '/tmp/chef-automate')
aibfile = attribute('aibfile', default: '/tmp/chef-automate.aib')

describe.one do
  describe file(aibchef) do
    it { should exist }
    it { should be_file }
    its('mode') { should cmp '0755' }
  end

  describe file(fcpchef) do
    it { should exist }
    it { should be_file }
    its('mode') { should cmp '0755' }
  end
end

describe.one do
  describe file(aibfile) do
    it { should exist }
    it { should be_file }
  end

  describe file(fcpfile) do
    it { should exist }
    it { should be_file }
  end
end
