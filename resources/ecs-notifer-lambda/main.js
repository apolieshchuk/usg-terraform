const https = require('https');

exports.handler = async (event) => {
    const textMsg = {
        username: `AWS LAMBDA`,
        icon_emoji: ':lambda_bg:',
        text: `:lambda: AWS ECS Task ${event.detail?.desiredStatus} Event`,
        attachments: [
            {
                color: event.detail?.desiredStatus === 'STOPPED' ? '#FFCC00' : '#2eb886',
                fields: [
                    {
                        title: 'Environment',
                        value: event.detail?.group || '',
                        short: true,
                    },
                    {
                        title: ':white_small_square: Message',
                        value: `ECS Task State Change to ${event.detail?.lastStatus}`,
                        short: false, // marks this to be wide attachment
                    },
                    event.detail?.desiredStatus === 'STOPPED' && {
                        title: ':white_small_square: Stopped Reason',
                        value: event.detail?.stoppedReason || '',
                        short: false, // marks this to be wide attachment
                    },
                    {
                        title: ':white_small_square: Task',
                        value: event.detail?.taskArn,
                        short: false, // marks this to be wide attachment
                    },
                ],
            },
        ],
    }
    // Promisify the https.request
    return new Promise((resolve, reject) => {
        // general request options, we defined that it's a POST request and content is JSON
        const requestOptions = {
            method: 'POST',
            header: {
                'Content-Type': 'application/json'
            }
        };

        // actual request
        const req = https.request('https://hooks.slack.com/services/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',
            requestOptions, (res) => {
                let response = '';


                res.on('data', (d) => {
                    response += d;
                });

                // response finished, resolve the promise with data
                res.on('end', () => {
                    resolve(response);
                })
            });

        // there was an error, reject the promise
        req.on('error', (e) => {
            reject(e);
        });

        // send our message body (was parsed to JSON beforehand)
        req.write(JSON.stringify(textMsg));
        req.end();
    });
};
