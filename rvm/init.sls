{% set rvm = pillar.get('rvm', {}) %}
{% set version = rvm.get('version', 'stable') %}

rvm-packages-tar:
  pkg.installed:
    - name: tar

rvm-packages-curl:
  pkg.installed:
    - name: curl

rvm-install-gpgkey:
  cmd:
    - run
    - user: root
    - name: gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    - unless: gpg --list-keys | grep D39DC0E3

rvm-install:
  cmd:
    - run
    - user: root
    - name: curl -sSL https://get.rvm.io | bash -s {{ version }}
    - onlyif: test ! -f /usr/local/rvm/bin/rvm

install-ruby-requirements:
  cmd.run:
    - name: /usr/local/rvm/bin/rvm requirements

# install rvm.rubies

{% for ruby_version, ruby_row in salt['pillar.get']('rvm:rubies', {}).items() %}

rvm-install-ruby-{{ruby_version}}:
  cmd:
    - run
    - user: root
    - name: /usr/local/rvm/bin/rvm install {{ruby_version}}
    - onlyif: test ! -d /usr/local/rvm/rubies/ruby-{{ruby_version}}

# set default if needed
{% if 'default' in ruby_row %}
{% if ruby_row.default == True %}

rvm-default-use:
  cmd.run:
    - name: bash -l -c "rvm --default use {{ ruby_version }}"

{% endif %}
{% endif %}

# install gemsets and install gems if needed
{% if 'gemsets' in ruby_row %}
{% for gemset,gems  in ruby_row.gemsets.items() %}

rvm-create-gemset-{{ruby_version}}-{{gemset}}:
  cmd:
    - run
    - user: root
    - name: "bash -l -c 'rvm use {{ruby_version}} ; rvm gemset create {{gemset}}'"
    - unless: "bash -l -c 'rvm use {{ruby_version}}; rvm gemset list | grep {{gemset}}'"

{% for gem in gems %}

{% set gem_r = gem.split("-") %}
{% set gem_version = "" %}
{% if gem_r[1] is defined %}
  {% set gem_version = "-v " + gem_r[1] %}
{% endif %}

rvm-install-gems-{{ruby_version}}-{{gemset}}-{{gem}}:
  cmd:
    - run
    - user: root
    - name: "bash -l -c 'rvm use {{ruby_version}} && rvm gemset use {{gemset}} && gem install {{gem_r[0]}} {{gem_version}}'"
    - unless: "bash -l -c 'rvm use {{ruby_version}} && rvm gemset use {{gemset}} && gem list | grep {{gem_r[0]}}'"

{% endfor %}

{% endfor %}

{% endif %}

{% endfor %}
