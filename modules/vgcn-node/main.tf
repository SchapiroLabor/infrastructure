resource "openstack_compute_instance_v2" "vgcn-node" {
  name            = "vgcnbwc-${var.name}-${count.index}"
  image_name      = "${var.image}"
  flavor_name     = "${var.flavor}"
  key_pair        = "cloud2"
  security_groups = ["public"]
  count           = "${var.count}"

  user_data = <<-EOF
    #cloud-config
    write_files:
    - content: |
        # BEGIN MANAGED BLOCK
        ETC = /etc/condor
        CONDOR_HOST = manager.vgcn.galaxyproject.eu
        ALLOW_WRITE = 10.5.68.0/24, 10.19.0.0/16, 132.230.68.0/24, *.bi.uni-freiburg.de
        ALLOW_READ = $(ALLOW_WRITE)
        ALLOW_ADMINISTRATOR = 10.5.68.0/24, 10.19.0.0/16
        ALLOW_NEGOTIATOR = $(ALLOW_ADMINISTRATOR)
        ALLOW_CONFIG = $(ALLOW_ADMINISTRATOR)
        ALLOW_DAEMON = $(ALLOW_ADMINISTRATOR)
        ALLOW_OWNER = $(ALLOW_ADMINISTRATOR)
        ALLOW_CLIENT = *
        DAEMON_LIST = MASTER, SCHEDD, STARTD
        FILESYSTEM_DOMAIN = bi.uni-freiburg.de
        UID_DOMAIN = bi.uni-freiburg.de
        TRUST_UID_DOMAIN = True
        SOFT_UID_DOMAIN = True
        CLAIM_PARTITIONABLE_LEFTOVERS = True
        NUM_SLOTS = 1
        NUM_SLOTS_TYPE_1 = 1
        SLOT_TYPE_1 = 100%
        SLOT_TYPE_1_PARTITIONABLE = True
        ALLOW_PSLOT_PREEMPTION = False
        STARTD.PROPORTIONAL_SWAP_ASSIGNMENT = True
        # END MANAGED BLOCK
        GalaxyTraining = ${var.is_training}
        GalaxyGroup = ${var.name}
        STARTD_ATTRS = GalaxyTraining, GalaxyGroup
      owner: root:root
      path: /etc/condor/condor_config.local
      permissions: '0644'
    - content: |
        /data           /etc/auto.data          nfsvers=3
        /-              /etc/auto.usrlocal      nfsvers=3
      owner: root:root
      path: /etc/auto.master.d/data.autofs
      permissions: '0644'
    - content: |
        0       -rw,hard,intr,nosuid,quota      sn01.bi.uni-freiburg.de:/export/data3/galaxy/net/data/&
        1       -rw,hard,intr,nosuid,quota      sn03.bi.uni-freiburg.de:/export/galaxy1/data/&
        2       -rw,hard,intr,nosuid,quota      sn01.bi.uni-freiburg.de:/export/data4/galaxy/net/data/&
        3       -rw,hard,intr,nosuid,quota      sn01.bi.uni-freiburg.de:/export/data5/galaxy/net/data/&
        4       -rw,hard,intr,nosuid,quota      sn03.bi.uni-freiburg.de:/export/galaxy1/data/&
        5       -rw,hard,intr,nosuid,quota      sn03.bi.uni-freiburg.de:/export/galaxy1/data/&
        6       -rw,hard,intr,nosuid,quota      sn03.bi.uni-freiburg.de:/export/galaxy1/data/&
        7       -rw,hard,intr,nosuid,quota      sn03.bi.uni-freiburg.de:/export/galaxy1/data/&
        dnb01   -rw,hard,intr,nosuid,quota      ufr.isi1.public.ads.uni-freiburg.de:/ifs/isi1/ufr/bronze/nfs/denbi/&
        dnb02   -rw,hard,intr,nosuid,quota      ufr.isi1.public.ads.uni-freiburg.de:/ifs/isi1/ufr/bronze/nfs/denbi/&
        dnb03   -rw,hard,intr,nosuid,quota      ufr.isi1.public.ads.uni-freiburg.de:/ifs/isi1/ufr/bronze/nfs/denbi/&
        dnb04   -rw,hard,intr,nosuid,quota      ufr.isi1.public.ads.uni-freiburg.de:/ifs/isi1/ufr/bronze/nfs/denbi/&
        db      -rw,hard,intr,nosuid,quota      sn02.bi.uni-freiburg.de:/export/fdata1/galaxy/net/data/&
      owner: root:root
      path: /etc/auto.data
      permissions: '0644'
    - content: |
        /usr/local/python  -rw,hard,intr,nosuid,quota      sn03.bi.uni-freiburg.de:/export/usr.local/sclx/6/x64/python
        /usr/local/galaxy  -rw,hard,intr,nosuid,quota      sn03.bi.uni-freiburg.de:/export/galaxy1/system/galaxy
        /usr/local/tools   -rw,hard,intr,nosuid,quota      sn03.bi.uni-freiburg.de:/export/galaxy1/system/tools
        /opt/galaxy        -rw,hard,intr,nosuid,quota      sn03.bi.uni-freiburg.de:/export/galaxy1/system/galaxy-i1
      owner: root:root
      path: /etc/auto.usrlocal
      permissions: '0644'
  EOF

  network {
    name = "bioinf"
  }

  provisioner "remote-exec" {
    when = "destroy"

    scripts = [
      "./conf/prepare-restart.sh",
    ]

    connection {
      type        = "ssh"
      user        = "centos"
      private_key = "${file("~/.ssh/keys/id_rsa_cloud2")}"
    }
  }
}
