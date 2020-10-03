configuration windowsfeatures {

    Import-DscResource -ModuleName PsDesiredStateConfiguration

    node localhost {

        WindowsFeature WebServer {
            Ensure = "Present"
            Name = "Web-Server"
        }
    }
}