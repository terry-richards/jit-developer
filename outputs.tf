output "instance_details" {
  value = <<EOF
Initialization complete! 👏

To connect via ssh:
$ ssh -i ${var.output_dir}/${local.developer_user_name}-key-pair.pem ubuntu@${aws_instance.developer.public_dns}

This instance will take several minutes to install the development environmment. You can monitor the progress of 
the initialization by running:
$ tail -f /var/log/cloud-init-output.log

Once the 'final' module has completed, the instance will reboot:
...
Cloud-init v. 23.2.1-0ubuntu0~22.04.1 running 'modules:config' at Fri, 04 Aug 2023 01:53:16 +0000. Up 10.26 seconds.
Cloud-init v. 23.2.1-0ubuntu0~22.04.1 running 'modules:final' at Fri, 04 Aug 2023 01:53:17 +0000. Up 11.11 seconds.
Cloud-init v. 23.2.1-0ubuntu0~22.04.1 finished at Fri, 04 Aug 2023 01:53:17 +0000. Datasource DataSourceEc2Local.  
Up 11.24 seconds

You can now connect via VNC:
$ ssh -L 5901:localhost:5901 -f -i ${var.output_dir}/${local.developer_user_name}-key-pair.pem ubuntu@${aws_instance.developer.public_dns} 'vncserver --SecurityTypes None > /dev/null && sleep 30'; sleep 5 && vncviewer -FullScreen -FullScreenMode=All -SecurityTypes=None localhost:5901 &> /dev/null &

This will start a VNC server on the instance and connect you to it. This assumes you have a vncviewer installed on 
your local machine. If you do not, you can install one with:
$ sudo apt install tigervnc-viewer

NOTE: This approach bypasses the vnc passwd file because you are exclusively connecting to the VNC server via ssh 
tunnel and the password would be redundant. One was created however and can be found at /home/ubuntu/.vnc/passwd 
if you want to use it.

If you log out of the gnome session normally, the VNC server will be stopped automatically allowing you to reuse 
the above command.  If you need to stop the VNC server manually, you can do so with:
$ ssh -i ${var.output_dir}/${local.developer_user_name}-key-pair.pem ubuntu@${aws_instance.developer.public_dns} 'vncserver -kill :1'

EOF
}