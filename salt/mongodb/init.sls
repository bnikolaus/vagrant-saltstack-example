mongodb_directory:
  file.directory:
    - name: /opt/mongodb

 
download_mongo:
  file.managed:
    - name: /opt/mongodb/{{ pillar['mongodb_version'] }}.tgz  
    - source: {{ pillar['mongodb_download'] }} 
    - source_hash: {{ pillar['mongodb_md5'] }}


extract_mongo:
  cmd.wait:
    - name: tar --strip-components 1 -xvf {{ pillar['mongodb_version'] }}.tgz -C /opt/mongodb
    - cwd: /opt/mongodb
    - unless: test -f /opt/mongodb/bin/mongo 
    - watch:
      - file: download_mongo


/opt/mongodb/bin:
  file.directory:
    - dir_mode: 755
    - file_mode: 755
    - recurse:
      - mode
    - require:
      - file: /opt/mongodb

/etc/mongodb.conf:
  file.managed:
    - source: salt://mongodb/files/mongodb.conf
    - user: root
    - group: root
    - mode: 755


mongo_init_script:
  file.managed:
    - name: /etc/init.d/mongod  
    - source: salt://mongodb/files/mongod
    - template: jinja
    - user: root
    - group: root
    - mode: 755


symlink_mongod:
  file.symlink:
    - name: /usr/bin/mongod 
    - target: /opt/mongodb/bin/mongod


chkconfig_mongod_on:
  cmd.run:
    - name: chkconfig --add mongod
    - unless: chkconfig --list mongod
    - require:
      - file: /etc/init.d/mongod


mongo_log_dir:
  file.directory:
    - name: /var/log/mongodb
    - require:
      - file: /etc/mongodb.conf


mongo_data_dir:
  file.directory:
    - name: /opt/mongodb/mongodata/conf
    - makedirs: True 
    - recurse:
      - mode 
    - require:
      - cmd: extract_mongo 


mongo_db_dir:
  file.directory:
    - name: /opt/mongodb/mongodata/data/db
    - makedirs: True 
    - recurse:
      - mode
    - require:
      - cmd: extract_mongo


# openssl rand -base64 741 > key
mongo_key:
  file.managed:
    - name: /opt/mongodb/mongodata/conf/key
    - source: salt://mongodb/files/key 
    - user: root
    - group: root
    - mode: 600
    - require:
      - file: mongo_data_dir


mongodb:
  grains.present:
    - value: True


start_mongo:
  cmd.wait:
    - name: mongod --fork --config /etc/mongod.conf
  require:
    - file: mongo_key
    - file: mongo_db_dir


install_pymongo:
  pip.installed:
    - name: pymongo


mongouser-testuser:
  mongodb_user.present:
  - name: testuser 
  - passwd: testuser 
  - user: admin
  - password: ""

# needs to rewrite init script
#mongodb_service:
#  service:
#    - name: mongod
#    - running
#    - enable: True
#    - reload: True
#    - watch:
#      - file: /etc/mongodb.conf
