configuration NginxInstall {

    Import-DscResource -ModuleName nxtools

    Node "localhost" {

        nxPackage nginx {
            Name = "nginx"
            Ensure = "Present"
        }
    }
}

NginxInstall
