require_relative '../../scripts/ci/ci'
require 'tmpdir'

describe Ci do
  
  let(:credentials_path) {File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/ci.yml'}
  let(:aapb_workspace_id) {'051303c1c1d24da7988128e6d2f56aa9'} # we make sure NOT to use this.
  
  it 'requires credentials' do
    expect{Ci.new}.to raise_exception('No credentials given')
  end
  
  it 'catches option typos' do
    expect{Ci.new({typo: 'should be caught'})}.to raise_exception('Unrecognized options [:typo]')
  end
  
  it 'catches creditials specified both ways' do
    expect{Ci.new({credentials: {}, credentials_path: {}})}.to raise_exception('Credentials specified twice')
  end
  
  it 'catches missing credentials' do
    expect{Ci.new({credentials: {}})}.to raise_exception(
      'Expected ["client_id", "client_secret", "password", "username", "workspace_id"] in ci credentials, not []'
    )
  end
  
  it 'blocks some filetypes (small files)' do
    ci = get_ci
    Dir.mktmpdir do |dir|
      log_path = "#{dir}/log.txt"
      ['js','html','rb'].each do |disallowed_ext|
        path = "#{dir}/file-name.#{disallowed_ext}"
        File.write(path, "content doesn't matter")
        expect{ci.upload(path, log_path)}.to raise_exception(/Upload failed/)
      end
      expect(File.read(log_path)).to eq('')
    end
  end
  
  it 'allows .txt (small files)' do
    ci = get_ci
    Dir.mktmpdir do |dir|
      log_path = "#{dir}/log.txt"
      ['txt'].each do |allowed_ext|
        path = "#{dir}/file-name.#{allowed_ext}"
        File.write(path, "content doesn't matter")
        expect{ci.upload(path, log_path)}.not_to raise_exception
      end
      expect(File.read(log_path)).to match(/[^\t]+\tfile-name\.txt\t[0-9a-f]{32}\n/)
    end
  end
  
  def get_ci
    expect(YAML.load_file(credentials_path)).not_to eq(aapb_workspace_id)
    ci = Ci.new({credentials_path: credentials_path})
    expect(ci.access_token).to match(/[0-9a-f]{32}/)
    list = ci.list.map{|item| item['name']} - ['Workspace'] # A self reference is present even in an empty workspace.
    expect(list.count).to eq(0), "Expected workspace #{ci.workspace_id} to be empty, instead of #{list}"
    return ci
  end

end
