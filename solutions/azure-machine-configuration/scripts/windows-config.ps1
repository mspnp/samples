configuration windowsfeatures {

    Import-DscResource -ModuleName PSDscResources

    node localhost {

        WindowsFeature WebServer {
            Ensure = "Present"
            Name = "Web-Server"
        }
    }
}

windowsfeatures