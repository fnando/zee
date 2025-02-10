# https://puma.io/puma/Puma/DSL.html
threads_count = ENV.fetch("APP_MAX_THREADS", 3)
threads threads_count, threads_count

# Specifies the `port`. Default is 3000.
port ENV.fetch("PORT", 3000)

# Allow puma to be restarted by `bin/zee restart` command
# or `touch tmp/restart.txt`.
plugin :tmp_restart

# Specify the PID file.
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
