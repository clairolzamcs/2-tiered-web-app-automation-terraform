#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd.service
sudo systemctl enable httpd.service
{{!--sudo aws s3 cp s3://${env}-acs730-project-group10/images /var/www/html/images --recursive #copy all the images in the images folder of bucket--}}
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/
myip=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/local-ipv4`
echo "<html>
      <head>
        <title>GroupOne Webserver</title>
     </head>
     <body>
        <center>
            <h3>This webpage is created by</h3>
            <h2>${prefix}</h2>
            <h3>and the group members are</h3>
            <h2>${name}</h2>
            <h3>The private IP of the EC2 instance is $myip in ${env} environment</h3>
        </center>
        <br><br>
        {{!--<table border="5" bordercolor="grey" align="center">--}}
        {{!--<tr>--}}
        {{!--    <th colspan="3" height="50">PLACES TO VISIT IN ONTARIO</th> --}}
        {{!--</tr>--}}
        {{!--<tr>--}}
        {{!--    <th>Niagara Falls</th>--}}
        {{!--    <th>CN Tower</th>--}}
        {{!--    <th>Tobermory</th>--}}
        {{!--</tr>--}}
        {{!--<tr>--}}
        {{!--    <td><img src="images/NiagaraFalls.jpeg" alt="" border=3 height=200 width=300></img></th>--}}
        {{!--    <td><img src="images/cntower.jpeg" alt="" border=3 height=200 width=300></img></th>--}}
        {{!--    <td><img src="images/tobermory.jpeg" alt="" border=3 height=200 width=300></img></th>--}}
        {{!--</tr>--}}
        {{!--</table>--}}
      </body>
    <html>" > /var/www/html/index.html