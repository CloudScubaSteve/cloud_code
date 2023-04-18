import * as codepipeline from '@aws-cdk/aws-codepipeline';
import * as codepipelineActions from '@aws-cdk/aws-codepipeline-actions';
import * as codestarconnections from '@aws-cdk/aws-codestarconnections';
import * as cdk from 'aws-cdk-lib';
import * as cdkDeploy from 'aws-cdk-lib/aws-codepipeline-deployments';

import { Construct } from 'constructs';
import { CodePipeline, CodePipelineSource, ShellStep } from 'aws-cdk-lib/pipelines';
import {SecretValue} from "aws-cdk-lib";
import {CodeStarConnectionsSourceAction} from "aws-cdk-lib/aws-codepipeline-actions";

// const githubConnection = new codestarconnections.CfnConnection(this, 'GitHubConnection', {
//   connectionName: 'my-github-connection',
//   providerType: 'GitHub',
//   owner: 'my-github-username',
//   connectionProperties: {
//     'accessToken': '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'
//   }
// });
//
// const sourceOutput = new codepipeline.Artifact();
//
// const sourceAction = new codepipelineActions.CodeStarConnectionsSourceAction({
//   actionName: 'Source',
//   owner: 'CloudScubaSteve',
//   repo: 'cloud_code',
//   output: sourceOutput,
//   connectionArn: githubConnection.attrConnectionArn
// });

export class MyPipelineStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

	// question - how do I create a codestar connection for version 2 of github connectors,
	// and consume it when setting up the pipeline?
	// new CodeStarConnectionsSourceAction()

	  const pipeline = new CodePipeline(this, 'Pipeline', {
		  pipelineName: 'MyPipeline',
		  synth: new ShellStep('Synth', {
			  input: codepipelineActions.CodeStarConnectionsSourceAction({
                       actionName: 'Source',
                       owner: 'CloudScubaSteve',
                       repo: 'cloud_code',
                       output: sourceOutput,
                       connectionArn: githubConnection.attrConnectionArn
			  }),
			  commands: ['npm ci', 'npm run build', 'npx cdk synth']
		  })
	  });
  }
}
