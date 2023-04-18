import * as codepipeline from '@aws-cdk/aws-codepipeline';
import * as codepipelineActions from '@aws-cdk/aws-codepipeline-actions';
import * as codestarconnections from '@aws-cdk/aws-codestarconnections';
import * as cdk from 'aws-cdk-lib';
import * as cdkDeploy from 'aws-cdk-lib/aws-codepipeline-deployments';

import { Construct } from 'constructs';
import { CodePipeline, CodePipelineSource, ShellStep } from 'aws-cdk-lib/pipelines';
import {SecretValue} from "aws-cdk-lib";
import {CodeStarConnectionsSourceAction} from "aws-cdk-lib/aws-codepipeline-actions";

const githubConnection = new codestarconnections.CfnConnection(this, 'GitHubConnection', {
  connectionName: 'my-github-connection',
  providerType: 'GitHub',
  owner: 'CloudScubaSteve',
  connectionProperties: {
    'accessToken': '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'
  }
});

const sourceOutput = new codepipeline.Artifact();

const sourceAction = new codepipelineActions.CodeStarConnectionsSourceAction({
  actionName: 'Source',
  owner: 'CloudScubaSteve',
  repo: 'cloud_code',
  output: sourceOutput,
  connectionArn: githubConnection.attrConnectionArn
});


const pipeline = new codepipeline.Pipeline(this, 'MyPipeline', {
  stages: [
    {
      stageName: 'Source',
      actions: [sourceAction],
    }
  ],
});