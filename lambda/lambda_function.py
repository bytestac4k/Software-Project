"""
AWS Lambda entrypoint for the Model Evaluation System.

This function acts as a serverless API handler that accepts a JSON body
containing a list of URLs to analyze (Hugging Face models/datasets or GitHub repos),
runs the ModelEvaluator, and returns the computed metric scores.
"""

import json
import logging
from model_evaluator import ModelEvaluator

# Configure logging for AWS Lambda environment
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    AWS Lambda handler function.
    Input: event["body"] should be a JSON object like:
        {"urls": ["https://huggingface.co/bert-base-uncased",
                  "https://github.com/google-research/bert"]}
    Output: HTTP response with evaluation results or error message.
    """
    try:
        # Parse input payload from API Gateway request
        if event.get("body"):
            body = json.loads(event["body"])
        else:
            body = event

        urls = body.get("urls", [])

        if not urls:
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": "Missing 'urls' in request body"})
            }

        # Instantiate and run the evaluator
        evaluator = ModelEvaluator()
        results = evaluator.evaluate_urls(urls)

        # Return successful HTTP response
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "message": "Evaluation completed successfully",
                "results": results
            })
        }

    except Exception as e:
        logger.exception("Error running model evaluation")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "error": str(e),
                "message": "Internal server error while running evaluation"
            })
        }
