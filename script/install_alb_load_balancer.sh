#/bin/bash

CLUSTER_NAME='sp-eks-poc'
ENV='poc'
AWS_REGION='us-west-1'
AWS_ACCOUNT_ID='020738235777'

aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER_NAME

echo "-------------------------------------------------------------alb controller installation started-------------------------"
echo "-------------------------------------------------------------"
echo "-------------------------------------------------------------"

curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json
POLICY_NAME="AWSLoadBalancerController_"$ENV"_Policy"
aws iam create-policy --policy-name $POLICY_NAME --policy-document file://iam_policy.json
rm iam_policy.json


oidc_id=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)

oidc_id_string=$(aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4)
echo "oidc provider returned"

ALB_TRUST_POLICY="loadbalancer_role_trust_"$ENV"policy.json"
cat >$ALB_TRUST_POLICY <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::aws-account-id:oidc-provider/oidc.eks.region-code.amazonaws.com/id/oidc-id"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.region-code.amazonaws.com/id/oidc-id:aud": "sts.amazonaws.com",
                    "oidc.eks.region-code.amazonaws.com/id/oidc-id:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                }
            }
        }
    ]
}
EOF
sed -i "s/region-code/$AWS_REGION/" "$ALB_TRUST_POLICY"
sed -i "s/aws-account-id/$AWS_ACCOUNT_ID/" "$ALB_TRUST_POLICY"
sed -i "s/oidc-id/$oidc_id_string/" "$ALB_TRUST_POLICY"


ALB_ROLE="AmazonEKSLoadBalancerController_"$ENV"_Role"
aws iam create-role --role-name $ALB_ROLE --assume-role-policy-document file://"$ALB_TRUST_POLICY"

POLICY_ARN="arn:aws:iam::"$AWS_ACCOUNT_ID":policy/"$POLICY_NAME
aws iam attach-role-policy --policy-arn $POLICY_ARN --role-name $ALB_ROLE


cat >aws-load-balancer-controller-service-account.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::aws-account-id:role/alb-role-name
EOF

sed -i "s/aws-account-id/$AWS_ACCOUNT_ID/" aws-load-balancer-controller-service-account.yaml
sed -i "s/alb-role-name/$ALB_ROLE/" aws-load-balancer-controller-service-account.yaml

kubectl apply -f aws-load-balancer-controller-service-account.yaml

#HELM INSTAllation
echo "helm installation started for alb ingress controller"

helm repo add eks https://aws.github.io/eks-charts
helm repo update eks

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller 

echo "alb installation finished"

echo "-------------------------------------------------------------alb controller installation finished-------------------------"