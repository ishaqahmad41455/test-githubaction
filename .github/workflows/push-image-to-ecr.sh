name: Push Docker Image To AWS ECR
on:
  push:
    branches:
      - 'main'
      - 'copy-develop'
      - 'pre-main'

jobs:
  build:
    name: Building Docker Image
    runs-on: ubuntu-latest
    steps:
    - name: Check out code
      uses: actions/checkout@v2
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1

    - name: Determine ECR Repository name
      id: ecr_repository_name
      run: |
          if [[ $GITHUB_REF == "refs/heads/copy-develop" ]]; then
            echo "ECR_IMAGE_NAME=stable-life-development"  >> $GITHUB_OUTPUT
            echo "DOCKERFILE_NAME=Dockerfile.dev"  >> $GITHUB_OUTPUT
          elif [[ $GITHUB_REF == "refs/heads/main" ]]; then
            echo "ECR_IMAGE_NAME=stable-life-production"  >> $GITHUB_OUTPUT
            echo "DOCKERFILE_NAME=Dockerfile.production"  >> $GITHUB_OUTPUT
          else
            echo "The value of GITHUB_REF is $GITHUB_REF"
            echo "::error:: Branch not supported for deployment"
            exit 1
          fi
    - name: OutPut ECR Repository Name
      env: 
         ECR_IMAGE_NAME: ${{ steps.ecr_repository_name.outputs.ECR_IMAGE_NAME }}
      run: |
            echo " **** ECR Repository name is ${{ steps.ecr_repository_name.outputs.ECR_IMAGE_NAME }} ****"
            echo " **** Dockerfile name is ${{ steps.ecr_repository_name.outputs.DOCKERFILE_NAME }} ****"
      
    - name: Build, tag, and push image to Amazon ECR
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        ECR_REPOSITORY: ${{ steps.ecr_repository_name.outputs.ECR_IMAGE_NAME }}
        DOCKFILE_NAME: ${{ steps.ecr_repository_name.outputs.DOCKERFILE_NAME }}
        IMAGE_TAG: latest
      run: |
        docker build -f $DOCKFILE_NAME -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
