# frozen_string_literal: true

require 'rack/not_so_common_logger'
require 'rack/lint'
require 'rack/mock'
require 'timecop'

require 'logger'

RSpec.describe Rack::NotSoCommonLogger do
  obj    = 'foobar'
  length = obj.size

  app = Rack::Lint.new lambda { |_env|
    [200, { 'Content-Type' => 'text/html', 'Content-Length' => length.to_s }, [obj]]
  }

  app_without_length = Rack::Lint.new lambda { |_env|
    [200, { 'Content-Type' => 'text/html' }, []]
  }

  app_with_zero_length = Rack::Lint.new lambda { |_env|
    [200, { 'Content-Type' => 'text/html', 'Content-Length' => '0' }, []]
  }

  it 'logs to rack.errors by default' do
    res = Rack::MockRequest.new(described_class.new(app)).get('/')

    expect(res.errors).to_not be_empty
    expect(res.errors).to match(%r{"GET \/ " 200 #{length} })
  end

  it 'logs to anything with +write+' do
    log = StringIO.new
    Rack::MockRequest.new(described_class.new(app, log)).get('/')

    expect(log.string).to match(%r{"GET \/ " 200 #{length} })
  end

  it 'works with standartd library logger' do
    logdev = StringIO.new
    log = Logger.new(logdev)
    Rack::MockRequest.new(described_class.new(app, log)).get('/')

    expect(logdev.string).to match(%r{"GET \/ " 200 #{length} })
  end

  it 'logs - content length if header is missing' do
    res = Rack::MockRequest.new(described_class.new(app_without_length)).get('/')

    expect(res.errors).to_not be_empty
    expect(res.errors).to match(%r{"GET \/ " 200 - })
  end

  it 'logs - content length if header is zero' do
    res = Rack::MockRequest.new(described_class.new(app_with_zero_length)).get('/')

    expect(res.errors).to_not be_empty
    expect(res.errors).to match(%r{"GET \/ " 200 - })
  end

  it 'logs in almost common log format' do
    log = StringIO.new
    Timecop.freeze(Time.at(0)) do
      Rack::MockRequest.new(described_class.new(app, log)).get('/')
    end

    md = %r{\[([^\]]+)\] "(\w+) \/ " (\d{3}) \d+ ([\d\.]+)}.match(log.string)

    expect(md).to_not be_nil
    time, method, status, duration = *md.captures
    expect(time).to eq Time.at(0).strftime('%d/%b/%Y:%H:%M:%S %z')
    expect(method).to eq 'GET'
    expect(status).to eq '200'
    expect((0..1)).to include duration.to_f
  end

  context 'when the ENV variable "SHOW_USER_GROUP_IN_LOGS"' do
    let(:log) { StringIO.new }

    context 'is set to "true"' do
      before do
        ENV['SHOW_USER_GROUP_IN_LOGS'] = 'true'
      end

      it 'it does not strip out the "user_group" param' do
        Rack::MockRequest.new(described_class.new(app, log)).get('/?user_group=darth%40vader.net')

        expect(log.string).to match(%r{/\?user_group=darth%40vader\.net})
      end
    end

    context 'is not set' do
      before do
        ENV.delete('SHOW_USER_GROUP_IN_LOGS')
      end

      it 'it hashes out the "user_group" URL param' do
        Rack::MockRequest.new(described_class.new(app, log)).get('/?user_group=darth%40vader.net')

        expect(log.string).to match(%r{/\?user_group=XXXXX})
      end
    end
  end
end
