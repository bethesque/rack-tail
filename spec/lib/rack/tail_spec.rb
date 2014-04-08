require 'rack/tail'
require 'rack/test'

describe Rack::Tail do

  include Rack::Test::Methods

  def app
    Rack::Tail.new root, headers, mime_type, default_lines
  end

  let(:root) { './spec/fixtures' }
  let(:file_path) { root + file_name }
  let(:file_name) { "/test.txt" }
  let(:file_contents) { File.readlines(file_path).last(default_lines).join}
  let(:default_lines) { File.readlines(file_path).count + 1 }
  let(:mime_type) { 'text/plain' }
  let(:headers) { {} }

  describe "GET" do

    context "when the number of lines required is not specified and the default lines is less than the entire file" do

      let(:default_lines) { 3 }

      subject { get file_name }

      it "returns the default number of lines" do
        subject
        expect(last_response.body).to eq(file_contents)
      end

      it "sets a status of 206" do
        subject
        expect(last_response.status).to eq 206
      end
    end

    context "when the number of lines required is not specified and the default lines is more than the number of lines in the file" do

      subject { get file_name }

      it "returns the entire file" do
        subject
        expect(last_response.body).to eq(file_contents)
      end

      it "sets a status of 200" do
        subject
        expect(last_response.status).to eq 200
      end
    end

    context "when a number of lines is specified that is less than the number of lines in the file" do
      let(:file_contents) { File.readlines(file_path).last(2).join }

      subject { get file_name, "lines" => "2" }

      it "returns the last lines" do
        subject
        expect(last_response.body).to eq(file_contents)
      end

      it "sets a status of 206" do
        subject
        expect(last_response.status).to eq 206
      end
    end

    context "when a number of lines is specified that is more than the number of lines in the file" do

      subject { get file_name, "lines" => "40" }
      let(:file_contents) { File.read(file_path )}
      let(:default_lines) { 1 }

      it "returns the entire file" do
        subject
        expect(last_response.body).to eq(file_contents)
      end

      it "sets a status of 200" do
        subject
        expect(last_response.status).to eq 200
      end
    end

    context "when the file does not exist" do
      subject { get "something.txt" }

      it "sets a status of 404" do
        subject
        expect(last_response.status).to eq 404
      end
    end

    context "when the file requested is outside the root" do
      subject { get "../lib/rack/tail_file_spec.rb" }

      it "returns a 403 Forbidden" do
        subject
        expect(last_response.status).to eq 403
      end

      it "does not return the file" do
        subject
        expect(last_response.body).to_not eq(file_contents)
      end
    end

    context "when the file requested has a path with .. that resolves to a file within the root" do

      subject { get "../fixtures/blah/..#{file_name}" }

      it "returns a 200 Success" do
        subject
        expect(last_response).to be_successful
      end
    end
  end

  describe "HEAD" do

    subject { head file_name }

    context "when the number of lines required is not specified and the default is less than the number of lines in the file" do

      it "returns an empty body" do
        subject
        expect(last_response.body.size).to eq 0
      end

      xit "sets a status of 206" do
        subject
        expect(last_response.status).to eq 206
      end
    end

    context "when the number of lines required is not specified and the default is more than the number of lines in the file" do

      let(:default_lines) { File.readlines(file_path).count + 1 }

      it "returns an empty body" do
        subject
        expect(last_response.body.size).to eq 0
      end

      it "sets a status of 200" do
        subject
        expect(last_response.status).to eq 200
      end
    end

    context "when a number of lines is specified that is less than the number of lines in the file" do

      subject { head file_name, "lines" => "2" }
      let(:default_lines) { File.readlines(file_path).count + 1 }

      it "returns an empty body" do
        subject
        expect(last_response.body.size).to eq 0
      end

      xit "sets a status of 206" do
        subject
        expect(last_response.status).to eq 206
      end

    end

  end

  %w{PUT POST DELETE PATCH}.each do | http_method |

    describe http_method do
      it "returns a 405 Method Not Allowed response" do
        self.send(http_method.downcase.to_sym, "something")
        expect(last_response.status).to eq 405
      end
    end

  end

end