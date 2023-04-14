#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd.service
sudo systemctl enable httpd.service
sudo aws s3 cp ${s3_images_path} /var/www/html/images --recursive
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/
myip=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/local-ipv4`
cat <<EOF > /var/www/html/index.html
<html>
<head>
    <title>GroupOne Webserver</title>
</head>
<body>
<center>
<h3>This webpage is created by</h3>
<h2>${prefix}</h2>
<h3>and the group members are</h3>
<script>
    var members = ["Gelene Asuncion", "Adrian Nico Gomez", "Clairol Zam Salazar", "Roi Carlo Panaligan", "Meloudy Tubes Yodico"]
    var nameList = "";
        
    for (var i = 0; i < members.length; i++) {
        nameList += "<h3>" + members[i] + "</h3>\n";
    }
    document.write(nameList);
</script>
<h3>The private IP of the EC2 instance is $myip in ${env} environment</h3>
</center>
<br><br>
<table border="5" bordercolor="grey" align="center">
    <tr>
        <th colspan="3" height="50">FLOWERS YOU CAN GIVE ME</th> 
    </tr>
    <tr>
        <th>DAISY</th>
        <th>ROSE</th>
        <th>SUNFLOWER</th>
    </tr>
    <tr>
        <td><img src="images/daisy.jpeg" alt="" border=3 height=200 width=300></img></th>
        <td><img src="images/rose.jpeg" alt="" border=3 height=200 width=300></img></th>
        <td><img src="images/sunflower.jpeg" alt="" border=3 height=200 width=300></img></th>
    </tr>
</table>
</body>
<html>
EOF