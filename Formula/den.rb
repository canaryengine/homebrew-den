class DockerRequirement < Requirement
  fatal true

  DOCKER_MIN_VERS = "20.10.16"
  COMPOSE_MIN_VERS = "2.2.3"

  satisfy(build_env: false) { self.class.has_docker? }

  def message
    "Docker with Docker Compose >= #{COMPOSE_MIN_VERS} is " \
    "required for Den. Please install Docker Desktop via brew with 'brew " \
    "install --cask docker', download it from https://docker.com/ or use " \
    "your system package manager to install Docker Engine "\
    ">= #{DOCKER_MIN_VERS}"
  end

  def self.has_docker?
    self.docker_installed? &&
      (
        !self.docker_running? ||
        (
          self.docker_minimum_version_met? &&
          self.docker_compose_minimum_version_met?
        )
      )
  end

  def self.docker_running?
    docker_exec = self.get_docker_exec
    trash, status = Open3.capture2("#{docker_exec} system info")
    return status.success?
  end

  def self.docker_installed?
    return File.exists?("/Applications/Docker.app") &&
      File.exists?("/usr/local/bin/docker") if OS.mac?
    return File.exists?("/usr/bin/docker") if OS.linux?
  end

  def self.get_docker_exec
    return "/usr/local/bin/docker" if OS.mac?
    return "/usr/bin/docker" if OS.linux?
  end

  def self.docker_minimum_version_met?
    docker_exec = self.get_docker_exec
    current_vers, status =\
      Open3.capture2("#{docker_exec} version --format '{{.Server.Version}}'")
    return Gem::Version.new(current_vers) >= Gem::Version.new(DOCKER_MIN_VERS)
  end

  def self.docker_compose_minimum_version_met?
    docker_exec = self.get_docker_exec
    current_vers, status = Open3.capture2("#{docker_exec} compose version --short")
    return Gem::Version.new(current_vers) >= Gem::Version.new(COMPOSE_MIN_VERS)
  end
end

class Den < Formula
  desc "Den is a CLI utility for working with docker-compose environments"
  homepage "https://swiftotter.github.io/den"
  license "MIT"
  version "1.0.0-beta.13.2"
  url "https://github.com/canaryengine/den/archive/1.0.0-beta.13.2.tar.gz"
  sha256 "66ac1129d456fa075bdac565dec0875a6f29ebbfc015b0f853a8c62c88883ec0"
  head "https://github.com/canaryengine/den.git", :branch => "master"

  depends_on DockerRequirement

  def install
    prefix.install Dir["*"]
  end

  def caveats
    <<~EOS
      Den manages a set of global services on the docker host machine. You
      will need to have Docker running and Docker Compose (>= 2.2.3) available in 
      your local $PATH configuration prior to starting Den.

      To start warden simply run:
        den svc up
      
      This command will automatically run "den install" to setup a trusted
      local root certificate and sign an SSL certificate for use by services
      managed by warden via the "warden sign-certificate warden.test" command.
      To print a complete list of available commands simply run "den" without
      any arguments.
    EOS
  end
end
