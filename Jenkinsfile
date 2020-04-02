library "alauda-cicd"
def language = "java"
AlaudaPipeline {
    config = [
        agent: 'java',
        folder: '.',
        sonar: [
            binding: "sonarqube",
            enabled: false
        ],
    ]

    yaml = "alauda.yaml"
}
