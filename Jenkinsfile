library "alauda-cicd-enable-get-multi-arch-image"
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
