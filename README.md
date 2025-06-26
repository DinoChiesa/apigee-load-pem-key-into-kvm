# Example: loading a PEM-encoded key into KVM

This is a quick example that shows how to use a bash script and a curl command to
upload the multi-line contents of a file into a KVM entry, in Apigee X.
A typical case is a PEM-encoded public key that you want to put into a KVM Entry.

## Disclaimer

This example is not an official Google product, nor is it part of an
official Google product.


## Using it

To use this example, you need a bash shell, as well as:

- [gcloud CLI](https://cloud.google.com/sdk/docs/install)
- openssl
- jq
- tr, sed, cat

You can get all of these things in the [Google Cloud Shell](https://cloud.google.com/shell/docs/launching-cloud-shell).

### Steps

0. Set some environment variables for your Apigee project and environment:
   ```sh
   export APIGEE_PROJECT=my-project-id
   export APIGEE_ENV=my-environment
   ```

1. Create a keypair.

   This will use openssl to create a keypair, using the
   current time as a timestamp on the filenames.

   ```sh
   ./1-create-keypair.sh
   ```


2. Install apigeecli into $HOME/.apigeecli/bin

   This is good for managing apigee. Listing KVMs, updating KVMs, deploying proxies, and so on.
   You can skip this step if you already have apigeecli on your path.

   Install [the apigeecli tool](https://github.com/apigee/apigeecli)
   ```sh
   ./2-install-apigeecli.sh
   ```


3. Upload the generated key pair to an environment scoped KVM.

   This script will prompt you for the KVM name, and confirm before
   making any changes.

   ```sh
   3-upload-pem-to-kvm.sh
   ```

4. Deploy the Apigee API proxy that reads this KVM.

   ```sh
   ./4-import-and-deploy.sh
   ```

5. Invoke the proxy to retrieve the data items you just uploaded:

   ```sh
   curl -i -X GET \$your_apigee_endpoint/kvm-read-test-1/public\?map=NAME_OF_MAP
   curl -i -X GET \$your_apigee_endpoint/kvm-read-test-1/private\?map=NAME_OF_MAP
   ```

## License

This material is [Copyright © 2025 Google LLC](./NOTICE).
and is licensed under the [Apache 2.0 License](LICENSE). This includes the Java
code as well as the API Proxy configuration.

## Support

This example is open-source software, and is not a supported part of Apigee.  If
you need assistance, you can try inquiring on [the Google Cloud Community forum
dedicated to Apigee](https://goo.gle/apigee-community) There is no service-level
guarantee for responses to inquiries posted to that site.



