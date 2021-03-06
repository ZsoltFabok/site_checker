module IoSpecHelper
  def webmock(uri, status, content, headers = {"Content-Type"=>"text/html; charset=UTF-8"})
    stub_request(:get, uri).
      with(:headers => {'Accept'=>'*/*'}).\
      to_return(:status => status, :body => content, :headers => headers)
  end

  def filesystemmock(uri, content)
    FileUtils.mkdir_p(File.dirname(File.join(fs_test_path, uri)))
    File.open(File.join(fs_test_path, uri), "w") do |f|
      f.write(content)
    end
  end

  def clean_fs_test_path
    FileUtils.rm_rf(fs_test_path)
  end

  def fs_test_path
    "test_data_public"
  end
end