# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

- name: Install Application
  hosts: localhost
  vars:
    app_name: ${app_name}
    profile_script: ${profile_script}
    install_dir: ${install_dir}
    git_url: ${git_url}
    git_ref: ${git_ref}
    chmod_mode: ${chmod_mode}
    chown_owner: ${chown_owner}
    chgrp_group: ${chgrp_group}
    finalize_setup_script: ${finalize_setup_script}
  tasks:
  - name: Print Application Name
    ansible.builtin.debug:
      msg: "Running installation for application: {{app_name}}"

  - name: Add profile script for application
    ansible.builtin.copy:
      dest: /etc/profile.d/{{ app_name }}.sh
      mode: '0644'
      content: "{{ profile_script }}"

  - name: Create parent of install directory
    ansible.builtin.file:
      path: "{{ install_dir | dirname }}"
      state: directory

  - name: Acquire lock
    ansible.builtin.command:
      mkdir "{{ install_dir | dirname }}/.install_{{ app_name }}_lock"
    register: lock_out
    changed_when: lock_out.rc == 0
    failed_when: false

  - name: Clones into installation directory
    ansible.builtin.command: git clone --branch {{ git_ref }} {{ git_url }} {{ install_dir }}
    when: lock_out.rc == 0

  - name: chgrp on installation
    ansible.builtin.file:
      path: "{{ install_dir }}"
      group: "{{ chgrp_group }}"
      recurse: true
    when: chgrp_group != "" and lock_out.rc == 0

  - name: chown on installation
    ansible.builtin.file:
      path: "{{ install_dir }}"
      owner: "{{ chown_owner }}"
      recurse: true
    when: chown_owner != "" and lock_out.rc == 0

  - name: chmod on installation
    ansible.builtin.file:
      path: "{{ install_dir }}"
      mode: "{{ chmod_mode }}"
      recurse: true
    when: chmod_mode != "" and lock_out.rc == 0

  - name: Finalize Setup
    ansible.builtin.shell: "{{ finalize_setup_script }}"
    when: lock_out.rc == 0
