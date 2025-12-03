-- Enable pg_cron extension
create extension if not exists pg_cron with schema extensions;

-- Enable pg_net for HTTP requests (if not already enabled)
create extension if not exists pg_net with schema extensions;

-- Schedule morning email to run every hour
-- The edge function checks each household's preferred send time
select cron.schedule(
  'send-morning-emails',
  '0 * * * *',
  $$
  select net.http_post(
    url := 'https://uzxomgyifkgbfwmcwxbm.supabase.co/functions/v1/send-morning-email',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('supabase.service_role_key', true)
    ),
    body := '{}'::jsonb
  );
  $$
);
