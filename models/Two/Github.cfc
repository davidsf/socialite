component extends="BaseProvider" implements="socialite.models.contracts.IProvider" accessors="true"{

    /**
     * The scopes being requested.
     *
     * @var array
     */
    property name="scopes" type="array";

    /**
     * Constructor
     */
    function init( clientId, clientSecret, redirectUrl ){
        super.init( arguments.clientId, arguments.clientSecret, arguments.redirectUrl );
        variables.scopes = ['user:email'];

        return this;
    }

    /**
     * Get auth url
     */
    function getAuthUrl(state){
        return this.buildAuthUrlFromBase('https://github.com/login/oauth/authorize', state);
    }

    /**
     * Get token url
     */
    function getTokenUrl()
    {
        return 'https://github.com/login/oauth/access_token';
    }

    /**
     * Get the access token from the token response body.
     *
     * @param  string  body
     * @return string
     */
    function parseAccessToken( body ){
        var token = ToString( ToBinary( body ) );

        var parts = listToArray(token, "&");
        var at = parts[1];
        var access_token = listGetAt(at, 2, "=");
        return access_token;
    }

    /**
     * Get user by token
     */
    function getUserByToken( token ){
        var userUrl = 'https://api.github.com/user?access_token=' & token;

        var req = hyper.setMethod( "GET" )
                        .setHeader( name="Accept", value="application/vnd.github.v3+json" )
                        .setUrl( userUrl )
                        .send();

        var user = deserializeJson( req.getData() );

        if (ArrayFind( variables.scopes, 'user:email' )) {
            user['email'] = this.getEmailByToken(token);
        }
        return user;
    }

    /**
     * Get the email for the given access token.
     *
     * @param  string  token
     * @return string|null
     */
    function getEmailByToken(token){
        var emailsUrl = 'https://api.github.com/user/emails?access_token=' & token;
        try {

            var req = hyper.setMethod( "GET" )
                            .setHeader( name="Accept", value="application/vnd.github.v3+json" )
                            .setUrl( emailsUrl )
                            .send();

        } catch (Exception e) {
            return;
        }
        var emails = deserializeJson( req.getData() );
        for( email in emails ) {
            if ( email['primary'] AND email['verified'] ) {
                return email['email'];
            }
        }
    }

    /**
     * Map user
     */
    function mapUserToObject(user){
        return {
            id = user['id'], 
            nickname = user['login'], 
            name = structKeyExists( user, 'name' ) ? user['name'] : "",
            email = structKeyExists( user, 'email' ) ? user['email'] : "", 
            avatar = user['avatar_url'],
        };
    }

}