require 'yaml'

module Sneakers
  class Spawner

    def self.spawn
      worker_group_config_file = ENV['WORKER_GROUP_CONFIG'] || "./config/sneaker_worker_groups.yml"
      unless File.exists?(worker_group_config_file)
        puts "No worker group file found."
        puts "Specify via ENV 'WORKER_GROUP_CONFIG' or by convention ./config/sneaker_worker_groups.yml"
        Kernel.exit(1)
      end
      @pids = []
      @exec_string = "bundle exec rake sneakers:run"
      worker_config = YAML.load(File.read(worker_group_config_file))
      log "[#{Process.pid}] The number of entries in worker config: #{worker_config.size}"
      worker_config.keys.each do |group_name|
        workers = worker_config[group_name]['classes']
        workers = workers.join "," if workers.is_a?(Array)
        log "Ready to fork ##{Process.pid} parent process for the #{group_name} group"
        @pids << fork do
          @exec_hash = {"WORKERS"=> workers, "WORKER_COUNT" => worker_config[group_name]["workers"].to_s}
          log "Inside fork block of ##{Process.pid} process, exec hash: #{@exec_hash}"
          Kernel.exec(@exec_hash, @exec_string)
        end
      end
      log "[#{Process.pid}] The number of forked processes: #{@pids.size}"
      log "[#{Process.pid}] Forked processes pids: #{@pids}"
      ["TERM", "USR1", "HUP", "USR2"].each do |signal|
        Signal.trap(signal){ @pids.each{|pid| Process.kill(signal, pid) } }
      end
      Process.waitall
    end

    def self.log(message)
      open('./log/sneakers_spawner.log', 'a') do |file|
        file.puts message
      end
    end
  end
end
