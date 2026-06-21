import boto3
from botocore.exceptions import BotoCoreError, ClientError

def main():
    try:
        session = boto3.Session()
        sts = session.client("sts")
        identity = sts.get_caller_identity()

        print("Connected to AWS")
        print(f"Account: {identity['Account']}")
        print(f"Arn: {identity['Arn']}")
        print(f"UserId: {identity['UserId']}")
    except (BotoCoreError, ClientError) as e:
        print("Failed to connect to AWS")
        print(str(e))
        raise

if __name__ == "__main__":
    main()
