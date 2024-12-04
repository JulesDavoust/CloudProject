# API
echo "Building and pushing API image..."
cd ../backend/API || exit 1
docker build -t api .
if [ $? -ne 0 ]; then
    echo "API build failed. Exiting script."
    exit 1
fi
docker tag api "$API_IMAGE"
docker push "$API_IMAGE"
if [ $? -ne 0 ]; then
    echo "API push failed. Exiting script."
    exit 1
fi