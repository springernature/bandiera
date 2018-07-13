require 'spec_helper'
require 'logger/stackdriver_json_formatter'

RSpec.describe Logger::StackdriverJsonFormatter do
  let(:msg)    { 'testing' }
  let(:target) { File.open('/dev/null', 'w+') }

  subject { described_class.new }

  let(:logger) do
    log = Logger.new(target)
    log.formatter = subject
    log
  end

  describe '#call' do
    it 'is called by the logger object' do
      expect(target).to receive(:write).once
      expect(subject).to receive(:call).once
      logger.info('this is a test')
    end

    describe 'the logging level' do
      it 'is passed into the severity key in the JSON message' do
        [:info, :warn, :debug].each do |severity|
          expect(target)
            .to receive(:write)
            .with(%({"severity":"#{severity.to_s.upcase}","message":"#{msg}"}\n))
            .once

          logger.public_send(severity, msg)
        end
      end
    end

    context 'when the log message is a string' do
      it 'logs the string in the JSON message' do
        expect(target)
          .to receive(:write)
          .with(%({"severity":"INFO","message":"#{msg}"}\n))
          .once

        logger.info(msg)
      end
    end

    context 'when the log message is an exception' do
      it 'returns full details of the exception' do
        ex = StandardError.new('qwerty')
        allow(ex).to receive(:backtrace).and_return(%w[foo bar baz])

        expected = JSON.generate({
          severity: 'INFO',
          message: "qwerty (StandardError)\nfoo\nbar\nbaz"
        })

        expect(target)
          .to receive(:write)
          .with(%(#{expected}\n))
          .once

        logger.info(ex)
      end
    end

    context 'when the log message is NOT a string or exception' do
      it 'returns object.inspect' do
        ex = []
        expect(ex).to receive(:inspect).once
        logger.info(ex)
      end
    end
  end
end
