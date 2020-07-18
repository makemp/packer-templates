# frozen_string_literal: true

# Cookbook Name:: travis_ci_ubuntu_2004
# Recipe:: default
#
# Copyright 2017, Travis CI GmbH
#
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

include_recipe 'travis_build_environment::apt'
include_recipe 'travis_packer_templates'
include_recipe 'travis_build_environment'

if node['travis_packer_templates']['env']['PACKER_BUILDER_TYPE'] == 'docker'
  if node['kernel']['machine'] == 'ppc64le'
    include_recipe 'travis_docker::package'
  else
    include_recipe 'travis_docker::binary'
  end
else
  if node['travis_packer_templates']['env']['PACKER_BUILDER_TYPE'] == 'lxd'
    node.override['travis_docker']['update_grub'] = false
  end
  include_recipe 'travis_docker'
  include_recipe 'travis_build_environment::ramfs'
end
include_recipe 'travis_docker::compose'
include_recipe 'openssl'
if node['kernel']['machine'] == 'ppc64le'
  include_recipe 'travis_java'
else
  include_recipe 'travis_jdk'
end
include_recipe 'travis_build_environment::maven'
include_recipe 'travis_build_environment::lein'
include_recipe 'travis_sbt_extras'
include_recipe 'travis_build_environment::gradle'
# include_recipe 'travis_postgresql'
# include_recipe 'travis_build_environment::mysql'
include_recipe 'travis_perlbrew::multi'
include_recipe 'travis_build_environment::redis'
# include_recipe 'travis_build_environment::mongodb'
include_recipe 'memcached'
# TODO: Uncomment when cassandra works on Java 8 again
# https://github.com/travis-ci/packer-templates/issues/589
# include_recipe 'travis_build_environment::cassandra'
# include_recipe 'travis_build_environment::couchdb'
include_recipe 'travis_build_environment::elasticsearch'
include_recipe 'travis_build_environment::xserver'
include_recipe 'travis_build_environment::google_chrome'
include_recipe 'travis_build_environment::firefox'
include_recipe 'travis_phantomjs::2'

# HACK: ubuntu_1804-specific shims!
execute 'ln -svf /usr/bin/hashdeep /usr/bin/md5deep'

log 'trigger writing node attributes' do
  notifies :run, 'ruby_block[write node attributes]'
end

log 'trigger job-board registration' do
  notifies :run, 'ruby_block[write job-board registration bits]'
end

include_recipe 'travis_system_info'

# HACK: force removal of ~/.pearrc until a decision is reached on if they are
# good or bad
execute 'rm -f /home/travis/.pearrc'

# install erlang
# add erlan gpgp key
execute 'add_erlang_gpg_key' do
  command 'wget -O- https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | sudo apt-key add -'
end
# add erlang repo
execute 'add_erlang_repository' do
  command 'echo "deb https://packages.erlang-solutions.com/ubuntu focal contrib" | sudo tee /etc/apt/sources.list.d/rabbitmq.list'
end
# update apt for erlang repo
apt_update
# install erlang
package 'erlang' do
  action :install
end

# add elasticsearch gpg key
execute 'add_elasticsearch_gpg_key' do
  command 'wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -'
end
# add elasticsearch repo
execute 'add_elasticsearch_repository' do
  command 'echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list'
end
# update apt
apt_update
# install elasticsearch
package 'elasticsearch' do
  action :install 
end
# enable elasticsearch service
service 'elasticsearch' do
  :enable 
end

include_recipe '::postgresql'