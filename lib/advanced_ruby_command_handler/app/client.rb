# frozen_string_literal: true

require "discordrb"
require "fileutils"
require "yaml"
require_relative "command_handler"
require_relative "event_handler"

module AdvancedRubyCommandHandler
  class Client < Discordrb::Bot
    attr_reader :commands_dir, :events_dir, :commands, :config, :console_logger, :file_logger

    def initialize(commands_dir: "commands", events_dir: "events", config_file: "config.yml")
      FileUtils.mkdir_p [commands_dir, events_dir]
      @commands_dir = commands_dir
      @events_dir = events_dir
      @file_logger = AdvancedRubyCommandHandler::Logger.new(:file)
      @console_logger = AdvancedRubyCommandHandler::Logger.new(:console)

      base_data = YAML.dump({
                              :token => "",
                              :prefix => "",
                              :owners => []
                            })

      File.open(config_file, "w+") { |file| file.write(base_data) } unless File.exist? config_file

      @config = YAML.load_file(config_file)

      %i[token prefix owners].each do |prop|
        next if @config[prop] && !@config[prop].empty?

        @console_logger.error("You have to add '#{prop.to_s}' value in your config file")
        raise "'#{prop}' missing or empty"
      end

      super(:token => @config[:token])

      @commands = AdvancedRubyCommandHandler::CommandHandler.load_commands(self)
      events = AdvancedRubyCommandHandler::EventHandler.load_events(self)
      events.each do |event|
        Events.method(event).call(self)
      end
    end

    def run
      @console_logger.info("Client login!")
      super.run
    end
  end
end