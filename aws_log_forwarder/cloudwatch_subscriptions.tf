resource "aws_cloudwatch_log_subscription_filter" "this" {
  for_each        = { for key in local.log_groups_with_individual_subscription: key => var.destination_config[key] }
  name            = var.name
  log_group_name  = each.key
  filter_pattern  = ""
  destination_arn = aws_lambda_function.this.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "${replace(title(replace(var.name, "_", " ")), " ", "")}AllowExecutionFromCloudwatch"
  action        = "lambda:InvokeFunction"
  function_name = var.name
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"
}

resource "aws_cloudwatch_log_account_policy" "subscription_filter" {
  count       = var.account_level_cloudwatch_subscription.enable ? 1 : 0
  policy_name = "subscription-filter"
  policy_type = "SUBSCRIPTION_FILTER_POLICY"
  policy_document = jsonencode(
    {
      DestinationArn = aws_lambda_function.this.arn
      FilterPattern  = ""
    }
  )
  selection_criteria = "LogGroupName NOT IN [${join(",", formatlist("\"%s\"", local.excluded_log_groups))}]"
  depends_on = [aws_lambda_permission.allow_cloudwatch, aws_lambda_function.this]
}
