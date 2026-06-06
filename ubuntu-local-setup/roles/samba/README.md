Role Name
=========

A brief description of the role goes here.

Requirements
------------

Any pre-requisites that may not be covered by Ansible itself or the role should be mentioned here. For instance, if the role uses the EC2 module, it may be a good idea to mention in this section that the boto package is required.

Role Variables
--------------

A description of the settable variables for this role should go here, including any variables that are in defaults/main.yml, vars/main.yml, and any variables that can/should be set via parameters to the role. Any variables that are read from other roles and/or the global scope (ie. hostvars, group vars, etc.) should be mentioned here as well.

Customizations for this repo
---------------------------

- `vfs_audit` (boolean): when set to `true` for a share in `first_samba_shares`, the template will include a VFS `full_audit` configuration block for that share.
- `second_samba_shares`: entries are rendered as commented blocks in the generated config so they remain available but inactive. Remove the leading `# ` to enable and adjust values as needed.

Example (defaults/main.yml):

```
first_samba_shares:
  - sharename: CCEPL_SERVER
    comment: "CCEPL Server DATA Share"
    shardirname: CCEPL_SERVER
    browseable: "yes"
    read_only: "no"
    writable: "yes"
    guest_ok: "no"
    valid_users: cce
    vfs_audit: true
```

Notes:
- The role writes timestamped backups of the Samba config before modifying it.
- The template uses `samba_shares_root` and `shardirname` to construct default `path` values.
- Use `ansible-playbook -t samba-conf --check` to dry-run changes for this role.

Group vars recommendation:
- Put `datacenter_map` in `group_vars/all.yml` to share mappings across roles and avoid duplication. Example:

```
datacenter_map:
  AV-PC: "GreaterNoida"
  WEB-01: "Mumbai-DC"
```

Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
