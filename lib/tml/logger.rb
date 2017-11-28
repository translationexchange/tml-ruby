# encoding: UTF-8
#--
# Copyright (c) 2017 Translation Exchange, Inc
#
#  _______                  _       _   _             ______          _
# |__   __|                | |     | | (_)           |  ____|        | |
#    | |_ __ __ _ _ __  ___| | __ _| |_ _  ___  _ __ | |__  __  _____| |__   __ _ _ __   __ _  ___
#    | | '__/ _` | '_ \/ __| |/ _` | __| |/ _ \| '_ \|  __| \ \/ / __| '_ \ / _` | '_ \ / _` |/ _ \
#    | | | | (_| | | | \__ \ | (_| | |_| | (_) | | | | |____ >  < (__| | | | (_| | | | | (_| |  __/
#    |_|_|  \__,_|_| |_|___/_|\__,_|\__|_|\___/|_| |_|______/_/\_\___|_| |_|\__,_|_| |_|\__, |\___|
#                                                                                        __/ |
#                                                                                       |___/
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'logger'

module Tml

  def self.logger
    @logger ||= begin
      logfile_path = File.expand_path(Tml.config.logger[:path] || './log/tml.log')
      logfile_dir = logfile_path.split("/")[0..-2].join("/")
      FileUtils.mkdir_p(logfile_dir) unless File.exist?(logfile_dir)
      logfile = File.open(logfile_path, 'a')
      logfile.sync = true

      logger = Tml::Logger.new(logfile)
      if Tml.config.logger[:type].to_s == 'rails'
        logger.external_logger = Rails.logger
      end

      logger
    end
  end

  def self.logger=(logger)
    @logger = logger
  end

  class Logger < ::Logger
    attr_accessor :external_logger

    def log_to_console(msg)
      return unless Tml.config.logger[:console]
      puts msg
    end

    def info(message)
      log_to_console(message)
      return external_logger.info(format_message(Logger::Severity::INFO, Time.new, nil, message)) if external_logger
      super
    end

    def debug(message)
      log_to_console(message)
      return external_logger.debug(format_message(Logger::Severity::DEBUG, Time.new, nil, message)) if external_logger
      super
    end

    def warn(message)
      log_to_console(message)
      return external_logger.warn(format_message(Logger::Severity::WARN, Time.new, nil, message)) if external_logger
      super
    end

    def error(message)
      log_to_console(message)
      return external_logger.error(format_message(Logger::Severity::ERROR, Time.new, nil, message)) if external_logger
      super
    end

    def fatal(message)
      log_to_console(message)
      return external_logger.fatal(format_message(Logger::Severity::FATAL, Time.new, nil, message)) if external_logger
      super
    end

    def format_message(severity, timestamp, progname, msg)
      return '' unless Tml.config.logger[:enabled]
      "[#{timestamp.strftime('%D %T')}]: tml: #{' ' * stack.size}#{msg}\n"
    end

    def add(severity, message = nil, progname = nil, &block)
      return unless Tml.config.logger[:enabled]
      super
    end

    def stack
      @stack ||= []
    end

    def trace(message)
      debug(message)
      stack.push(caller)
      t0 = Time.now
      if block_given?
        ret = yield
      end
      t1 = Time.now
      stack.pop
      debug("execution took #{t1 - t0} seconds")
      ret
    end

  end

end

