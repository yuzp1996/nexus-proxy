library "alauda-cicd"
def language = "java"
AlaudaPipeline {
    config = [
        agent: 'harborbuild',
        folder: '.',
        sonar: [
            binding: "sonarqube",
            enabled: false
        ],
    ]

    yaml = "alauda.yaml"
}
