# -*- encoding: utf-8 -*-
#
# Author:: Fletcher Nichol (<fnichol@nichol.ca>)
#
# Copyright (C) 2013, Fletcher Nichol
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative '../../spec_helper'

require 'kitchen/errors'
require 'kitchen/util'
require 'kitchen/loader/yaml'

class Yamled
  attr_accessor :foo
end

describe Kitchen::Loader::YAML do

  let(:loader) { Kitchen::Loader::YAML.new("/tmp/.kitchen.yml") }

  before do
    FakeFS.activate!
    FileUtils.mkdir_p("/tmp")
  end

  after do
    FakeFS.deactivate!
    FakeFS::FileSystem.clear
  end

  describe ".initialize" do

    it "sets config_file based on Dir.pwd by default" do
      loader = Kitchen::Loader::YAML.new

      loader.config_file.must_equal File.expand_path(
        File.join(Dir.pwd, '.kitchen.yml'))
    end

    it "sets config_file from parameter, if given" do
      loader = Kitchen::Loader::YAML.new('/tmp/crazyfunkytown.file')

      loader.config_file.must_equal '/tmp/crazyfunkytown.file'
    end
  end

  describe "#read" do

    it "returns a hash of kitchen.yml with symbolized keys" do
      stub_yaml!({
        'foo' => 'bar'
      })

      loader.read.must_equal({ :foo => 'bar' })
    end

    it "deep merges in kitchen.local.yml configuration with kitchen.yml" do
      stub_yaml!(".kitchen.yml", {
        'common' => { 'xx' => 1 },
        'a' => 'b'
      })
      stub_yaml!(".kitchen.local.yml", {
        'common' => { 'yy' => 2 },
        'c' => 'd'
      })

      loader.read.must_equal({
        :a => 'b',
        :c => 'd',
        :common => { :xx => 1, :yy => 2 }
      })
    end

    it "deep merges in a global config file with all other configs" do
      stub_yaml!(".kitchen.yml", {
        'common' => { 'xx' => 1 },
        'a' => 'b'
      })
      stub_yaml!(".kitchen.local.yml", {
        'common' => { 'yy' => 2 },
        'c' => 'd'
      })
      stub_global!({
        'common' => { 'zz' => 3 },
        'e' => 'f'
      })

      loader.read.must_equal({
        :a => 'b',
        :c => 'd',
        :e => 'f',
        :common => { :xx => 1, :yy => 2, :zz => 3 }
      })
    end

    it "merges kitchen.local.yml over configuration in kitchen.yml" do
      stub_yaml!(".kitchen.yml", {
        'common' => { 'thekey' => 'nope' }
      })
      stub_yaml!(".kitchen.local.yml", {
        'common' => { 'thekey' => 'yep' }
      })

      loader.read.must_equal({ :common => { :thekey => 'yep' } })
    end

    it "merges global config over both kitchen.local.yml and kitchen.yml" do
      stub_yaml!(".kitchen.yml", {
        'common' => { 'thekey' => 'nope' }
      })
      stub_yaml!(".kitchen.local.yml", {
        'common' => { 'thekey' => 'yep' }
      })
      stub_global!({
        'common' => { 'thekey' => 'kinda' }
      })

      loader.read.must_equal({ :common => { :thekey => 'kinda' } })
    end

    NORMALIZED_KEYS = {
      "driver" => "name",
      "provisioner" => "name",
      "busser" => "version"
    }

    NORMALIZED_KEYS.each do |key, default_key|

      describe "normalizing #{key} config hashes" do

        it "merges local with #{key} string value over yaml with hash value" do
          stub_yaml!(".kitchen.yml", {
            key => { 'dakey' => 'ya' }
          })
          stub_yaml!(".kitchen.local.yml", {
            key => 'namey'
          })

          loader.read.must_equal({
            key.to_sym => { default_key.to_sym => "namey", :dakey => 'ya' }
          })
        end

        it "merges local with #{key} hash value over yaml with string value" do
          stub_yaml!(".kitchen.yml", {
            key => 'namey'
          })
          stub_yaml!(".kitchen.local.yml", {
            key => { 'dakey' => 'ya' }
          })

          loader.read.must_equal({
            key.to_sym => { default_key.to_sym => "namey", :dakey => 'ya' }
          })
        end

        it "merges local with #{key} nil value over yaml with hash value" do
          stub_yaml!(".kitchen.yml", {
            key => { 'dakey' => 'ya' }
          })
          stub_yaml!(".kitchen.local.yml", {
            key => nil
          })

          loader.read.must_equal({
            key.to_sym => { :dakey => 'ya' }
          })
        end

        it "merges local with #{key} hash value over yaml with nil value" do
          stub_yaml!(".kitchen.yml", {
            key => 'namey'
          })
          stub_yaml!(".kitchen.local.yml", {
            key => nil
          })

          loader.read.must_equal({
            key.to_sym => { default_key.to_sym => "namey" }
          })
        end

        it "merges global with #{key} string value over yaml with hash value" do
          stub_yaml!(".kitchen.yml", {
            key => { 'dakey' => 'ya' }
          })
          stub_global!({
            key => 'namey'
          })

          loader.read.must_equal({
            key.to_sym => { default_key.to_sym => "namey", :dakey => 'ya' }
          })
        end

        it "merges global with #{key} hash value over yaml with string value" do
          stub_yaml!(".kitchen.yml", {
            key => 'namey'
          })
          stub_global!({
            key => { 'dakey' => 'ya' }
          })

          loader.read.must_equal({
            key.to_sym => { default_key.to_sym => "namey", :dakey => 'ya' }
          })
        end

        it "merges global with #{key} nil value over yaml with hash value" do
          stub_yaml!(".kitchen.yml", {
            key => { 'dakey' => 'ya' }
          })
          stub_global!({
            key => nil
          })

          loader.read.must_equal({
            key.to_sym => { :dakey => 'ya' }
          })
        end

        it "merges global with #{key} hash value over yaml with nil value" do
          stub_yaml!(".kitchen.yml", {
            key => nil
          })
          stub_global!({
            key => { 'dakey' => 'ya' }
          })

          loader.read.must_equal({
            key.to_sym => { :dakey => 'ya' }
          })
        end

        it "merges global, local, over yaml with mixed hash, string, nil values" do
          stub_yaml!(".kitchen.yml", {
            key => nil
          })
          stub_yaml!(".kitchen.local.yml", {
            key => "namey"
          })
          stub_global!({
            key => { 'dakey' => 'ya' }
          })

          loader.read.must_equal({
            key.to_sym => { default_key.to_sym => "namey", :dakey => 'ya' }
          })
        end
      end
    end

    it "handles a kitchen.local.yml with no yaml elements" do
      stub_yaml!(".kitchen.yml", {
        'a' => 'b'
      })
      stub_yaml!(".kitchen.local.yml", Hash.new)

      loader.read.must_equal({ :a => 'b' })
    end

    it "handles a kitchen.yml with no yaml elements" do
      stub_yaml!(".kitchen.yml", Hash.new)
      stub_yaml!(".kitchen.local.yml", {
        'a' => 'b'
      })

      loader.read.must_equal({ :a => 'b' })
    end

    it "handles a kitchen.yml with yaml elements that parse as nil" do
      stub_yaml!(".kitchen.yml", nil)
      stub_yaml!(".kitchen.local.yml", {
        'a' => 'b'
      })

      loader.read.must_equal({ :a => 'b' })
    end

    it "raises an UserError if the config_file does not exist" do
      proc { loader.read }.must_raise Kitchen::UserError
    end

    it "arbitrary objects aren't deserialized in kitchen.yml" do
      FileUtils.mkdir_p "/tmp"
      File.open("/tmp/.kitchen.yml", "wb") do |f|
        f.write <<-YAML.gsub(/^ {10}/, '')
          --- !ruby/object:Yamled
          foo: bar
        YAML
      end

      loader.read.class.wont_equal Yamled
      loader.read.class.must_equal Hash
      loader.read.must_equal({ :foo => 'bar' })
    end

    it "arbitrary objects aren't deserialized in kitchen.local.yml" do
      FileUtils.mkdir_p "/tmp"
      File.open("/tmp/.kitchen.local.yml", "wb") do |f|
        f.write <<-YAML.gsub(/^ {10}/, '')
          --- !ruby/object:Yamled
          wakka: boop
        YAML
      end
      stub_yaml!(".kitchen.yml", Hash.new)

      loader.read.class.wont_equal Yamled
      loader.read.class.must_equal Hash
      loader.read.must_equal({ :wakka => 'boop' })
    end

    it "raises a UserError if kitchen.yml cannot be parsed" do
      FileUtils.mkdir_p "/tmp"
      File.open("/tmp/.kitchen.yml", "wb") { |f| f.write '&*%^*' }

      proc { loader.read }.must_raise Kitchen::UserError
    end

    it "raises a UserError if kitchen.yml cannot be parsed" do
      FileUtils.mkdir_p "/tmp"
      File.open("/tmp/.kitchen.yml", "wb") { |f| f.write 'uhoh' }

      proc { loader.read }.must_raise Kitchen::UserError
    end

    it "raises a UserError if kitchen.local.yml cannot be parsed" do
      FileUtils.mkdir_p "/tmp"
      File.open("/tmp/.kitchen.local.yml", "wb") { |f| f.write '&*%^*' }
      stub_yaml!(".kitchen.yml", Hash.new)

      proc { loader.read }.must_raise Kitchen::UserError
    end

    it "evaluates kitchen.yml through erb before loading by default" do
      FileUtils.mkdir_p "/tmp"
      File.open("/tmp/.kitchen.yml", "wb") do |f|
        f.write <<-'YAML'.gsub(/^ {10}/, '')
          ---
          name: <%= "AHH".downcase + "choo" %>
        YAML
      end

      loader.read.must_equal({ :name => "ahhchoo" })
    end

    it "evaluates kitchen.local.yml through erb before loading by default" do
      FileUtils.mkdir_p "/tmp"
      File.open("/tmp/.kitchen.local.yml", "wb") do |f|
        f.write <<-'YAML'.gsub(/^ {10}/, '')
          ---
          <% %w{noodle mushroom}.each do |kind| %>
            <%= kind %>: soup
          <% end %>
        YAML
      end
      stub_yaml!(".kitchen.yml", { 'spinach' => 'salad' })

      loader.read.must_equal({
        :spinach => 'salad',
        :noodle => 'soup',
        :mushroom => 'soup'
      })
    end

    it "skips evaluating kitchen.yml through erb if disabled" do
      loader = Kitchen::Loader::YAML.new(
        '/tmp/.kitchen.yml', :process_erb => false)
      FileUtils.mkdir_p "/tmp"
      File.open("/tmp/.kitchen.yml", "wb") do |f|
        f.write <<-'YAML'.gsub(/^ {10}/, '')
          ---
          name: <%= "AHH".downcase %>
        YAML
      end

      loader.read.must_equal({ :name => '<%= "AHH".downcase %>' })
    end

    it "skips evaluating kitchen.local.yml through erb if disabled" do
      loader = Kitchen::Loader::YAML.new(
        '/tmp/.kitchen.yml', :process_erb => false)
      FileUtils.mkdir_p "/tmp"
      File.open("/tmp/.kitchen.local.yml", "wb") do |f|
        f.write <<-'YAML'.gsub(/^ {10}/, '')
          ---
          name: <%= "AHH".downcase %>
        YAML
      end
      stub_yaml!(".kitchen.yml", Hash.new)

      loader.read.must_equal({ :name => '<%= "AHH".downcase %>' })
    end

    it "skips kitchen.local.yml if disabled" do
      loader = Kitchen::Loader::YAML.new(
        '/tmp/.kitchen.yml', :process_local => false)
      stub_yaml!(".kitchen.yml", {
        'a' => 'b'
      })
      stub_yaml!(".kitchen.local.yml", {
        'superawesomesauceadditions' => 'enabled, yo'
      })

      loader.read.must_equal({ :a => 'b' })
    end

    it "skips the global config if disabled" do
      loader = Kitchen::Loader::YAML.new(
        '/tmp/.kitchen.yml', :process_global => false)
      stub_yaml!(".kitchen.yml", {
        'a' => 'b'
      })
      stub_global!({
        'superawesomesauceadditions' => 'enabled, yo'
      })

      loader.read.must_equal({ :a => 'b' })
    end
  end

  private

  def stub_file(path, hash)
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, "wb") { |f| f.write(hash.to_yaml) }
  end

  def stub_yaml!(name = ".kitchen.yml", hash)
    stub_file(File.join("/tmp", name), hash)
  end

  def stub_global!(hash)
    stub_file(File.join(File.expand_path(ENV["HOME"]),
      ".kitchen", "config.yml"), hash)
  end
end
