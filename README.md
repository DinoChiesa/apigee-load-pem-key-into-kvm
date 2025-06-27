# Example: loading a PEM-encoded key into KVM

This is a quick example that shows how to use a bash script and a curl command
to upload the multi-line contents of a file into a KVM entry, in Apigee X.  A
typical case is a PEM-encoded public key that you want to put into a KVM
Entry. This might look like the following:

```
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxC9tIfj2qZgdEsOauPj3
vsa1q11wr+iiyNbkCQe2snm02hxwJcHdGWCt1PNMf4C0f6XpGMl+cgOtWMwGWq8T
TQXqlcqa8DvY0wf7Qu7xjg+mKYJntP/L5bbtjDLZW8OnwHER146ScYu/tIrS4myz
yTFOR/2sGPORg9N0rJk9NYdekWN/9i2mMTMKbNQ7GrojmS0xuMMvkv+9PrlsyKf5
NL56edvbxTlqP5bPmglaJ/aEOtJB1XF6qR4r8Abc7BqN6hlLyq335KuFT/S/o40b
SjdFrzgZA2chMIZQwewQaGI8hVKJB/01dxrflMq75ICA0awJPCGAXrU5H774VSj5
EQIDAQAB
-----END PUBLIC KEY-----
```

The KVM UI for Apigee is... not necessarily helpful in allowing you to
upload/paste multiline content into the value box.  There is an outstanding
feature request to improve that experience. In the meantime, this repo includes
a script that shows you how to automate the task.

While this example shows the use of PEM-encoded RSA keys, obviously it works for
any multi-line text input you would like to load into a KVM, including JSON files,
CSV files, or anything else. The PEM-encoding is not the important part. It's just a
common scenario.

## Disclaimer

This example is not an official Google product, nor is it part of an
official Google product.

## Screencast

If you'd prefer to watch me walk through this example, 
[click here](https://youtu.be/OcVLt0pOVdg) for a quick screencast.


## Using it Yourself

To use this example, you need a bash shell, as well as:

- a Google Cloud project, with Apigee enabled on it
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

   You must also be signed in with gcloud.  So , if you need to, run `gcloud auth login`.

1. Create a keypair.

   This will use openssl to create a keypair, using the
   current time as a timestamp on the filenames.

   ```sh
   ./1-create-rsa-keypair.sh
   ```


2. Install [the apigeecli tool](https://github.com/apigee/apigeecli) into `$HOME/.apigeecli/bin`

   This is good for managing things inside Apigee. Listing KVMs, updating KVMs,
   importing and deploying proxies, and so on.  You can skip this step if you
   already have apigeecli on your path.

   ```sh
   ./2-install-apigeecli.sh
   ```


3. Upload the key pair you generated in step 1 to an environment-scoped KVM in Apigee.

   This script will prompt you for the KVM name, and confirm before
   making any changes.

   ```sh
   ./3-upload-pem-to-apigee-kvm.sh
   ```

   > Note: This script uploads a private key into the KVM.  This is not necessarily
   > a good idea for production use.  Normally you will want to store secrets like
   > a private key in the [Secret Manager](https://cloud.google.com/security/products/secret-manager) or similar.
   > If you do upload PEM-encoded private keys into the KVM, consider using a password-
   > encrypted private key. This example is only an example. Consult your security
   > advisor about all key management questions.

   After running this script, if you visit the Apigee UI in console.cloud.google.com, you
   should see entries for the keys you just uploaded.


4. Deploy the Apigee API proxy that reads this KVM.

   ```sh
   ./4-import-and-deploy-the-proxy.sh
   ```

5. Invoke the proxy to retrieve the data items you just uploaded:

   ```sh
   curl -i -X GET $your_apigee_endpoint/kvm-read-test-1/public\?map=NAME_OF_MAP
   curl -i -X GET $your_apigee_endpoint/kvm-read-test-1/private\?map=NAME_OF_MAP
   ```

## Cleanup

To undeploy and delete the sample proxy:
```sh
./00-cleanup.sh
```

This script does not remove the example items from the KVM.

## License

This material is [Copyright © 2025 Google LLC](./NOTICE).
and is licensed under the [Apache 2.0 License](LICENSE). This includes the bash scripts
as well as the API Proxy configuration.

## Support

This example is open-source software, and is not a supported part of Apigee.  If
you need assistance, you can try inquiring on [the Google Cloud Community forum
dedicated to Apigee](https://goo.gle/apigee-community) There is no service-level
guarantee for responses to inquiries posted to that site.
