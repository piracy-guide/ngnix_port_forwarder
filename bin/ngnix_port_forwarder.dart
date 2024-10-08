import 'dart:io';

void main(List<String> args) async {
  print(args);
  if (args.length < 4) throw "Not enough args";
  final subdomain = args[0];
  final domain = args[2];
  final port = int.parse(args[1]);
  final confirm = bool.parse(args[3]);
  final path = "/etc/nginx/sites-available/$subdomain.$domain";
  final file = File(path);
  final exits = await file.exists();
  if (exits && !confirm) throw "File already exist but it's not forced";
  await file.writeAsString("""
server {
    server_name $subdomain.$domain;
    location / {
        proxy_pass http://localhost:$port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
""");
  final cmds = [
    "sudo certbot --nginx -d $subdomain.$domain",
    "sudo ln -s $path /etc/nginx/sites-enabled/",
    "sudo certbot renew --dry-run",
    "sudo nginx -t",
    "sudo systemctl reload nginx",
  ];
  for (var e in cmds) {
    await CMD(e).run();
  }
}

class CMD {
  final String cmd;
  CMD(this.cmd);
  Future run() async {
    try {
      final x = await Process.run("bash", ["-c", cmd]);
      print("exitCode: ${x.exitCode}");
      print("pid: ${x.pid}");
      print("stderr: ${x.stderr}");
      print("stdout: ${x.stdout}");
    } catch (e) {
      throw "Error $e on running $cmd";
    }
  }
}
