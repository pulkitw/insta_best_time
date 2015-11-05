var app = angular.module('MyApp', []);

app.controller('BestTime', [
    '$scope', '$q', 'Instagram', function ($scope, $q, instagram) {
        var isPresent = function (x) {
            return x != undefined && x != null && x != '';
        };

        var setError = function (status) {
            $scope.error = status || "Request Failed";
            $scope.processing = false;
        };
        $scope.reset = function () {
            $scope.result = false;
            $scope.processing = false;
            $scope.user = {followers: {}};
            $scope.slice_followers = true;
            $scope.req_followers_count = 50;
            return;
        };

        var date = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

        $scope.reset();
        var fetchUserDetails = function(){
            if (isPresent($scope.error)) {
                return;
            }
            return instagram.fetchUser($scope.user.id, function (response) {
                var data = response.data;
                if(data){
                    $scope.user.name = data.username;
                    $scope.user.followers.count = data.counts.followed_by;
                }
                else{
                    setError(response.meta);
                }
            }, setError);
        };
        var fetchFollowersMedia = function(){
            if (isPresent($scope.error)) {
                return;
            }
            instagram.fetchFollowerIds($scope.user.id,$scope.slice_followers ? $scope.req_followers_count : null).then(function (response) {
                $scope.user.followers.fetched = response.length;
                $scope.user.followers.ids = response;
                if($scope.slice_followers && $scope.req_followers_count){
                    // using only first n followers to calculate data
                    $scope.user.followers.ids = response.slice(0, $scope.req_followers_count);
                }
                $scope.user.followers.processed = $scope.user.followers.ids.length;
                $q.all($scope.user.followers.ids.map(function (f) {
                    return instagram.fetchRecentMedia(f)
                })).then(
                    function (s) {
                        $scope.days = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
                        $scope.hours = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0, 8: 0, 9: 0, 10: 0, 11: 0, 12: 0, 13: 0, 14: 0, 15: 0, 16: 0, 17: 0, 18: 0, 19: 0, 20: 0, 21: 0, 22: 0, 23: 0}
                        s.forEach(function (response) {
                            var data = response.data;
                            if (data && data.data && data.data && data.data.length > 0) {
                                var d = new Date(parseInt(data.data[0].created_time) * 1000);
                                $scope.days[d.getDay()] += 1;
                                $scope.hours[d.getHours()] += 1
                            }
                        });
                        var getMax = function(obj,asDay){
                            var result = [];
                            var max = -1;
                            Object.keys(obj).forEach(function(k){
                                var r = asDay ? date[k] : k;
                                if(obj[k]>max){
                                    max=obj[k];
                                    result=[r];
                                }else if(obj[k]==max){
                                    result.push(r)
                                }
                            });
                            return result;
                        };
                        $scope.resultantDays = getMax($scope.days,true);
                        $scope.resultantHours = getMax($scope.hours);
                        $scope.processing = false;
                        $scope.result = true;

                    }, setError)
            },setError);
        };
        $scope.getBestTime = function () {
            $scope.error = null;
            $scope.result = false;
            $scope.processing = true;
            $scope.user.followers = {};
            if (!isPresent($scope.user.id) && !isPresent($scope.user.name)) {
                setError("User ID/Name must be present");
            }
            else if (!isPresent($scope.user.id)) {
                instagram.searchUser($scope.user.name,
                    function (data) {
                        if (!data.data || data.data.length == 0) {
                            if(data.meta.error_message){
                                setError(data.meta.error_message);
                            }else{
                            setError("No User with username:" + $scope.user.name + " found.");
                            }
                        }
                        else {
                            $scope.user.id = data.data[0].id;
                        }
                    }, setError).then(function(response){
                        var promise = fetchUserDetails();
                        if(promise){
                            promise.then(function(response){
                                fetchFollowersMedia();
                                return response;
                            });
                        }
                        return response;
                    })
            }
            else {
                var promise = fetchUserDetails();
                if(promise){
                    promise.then(function(response){
                        fetchFollowersMedia();
                        return response;
                    });
                }
            }
            return;
        }
    }
]);

app.service('Instagram', [
    '$http', '$q', function ($http, $q) {
        var InstaService;
        InstaService = (function () {
            function InstaService() {
                this.accessToken = "?access_token=1450729233.80cbc09.ac7d0b0b3adb423cb9551ef54ce05faf";
                this.baseUrl = "https://api.instagram.com/v1/users/";
                this.callbackType = "&callback=JSON_CALLBACK";
            }

            InstaService.prototype.fetchUser = function (user_id, successFn, failureFn) {
                var url = this.baseUrl + user_id + this.accessToken + this.callbackType;
                return $http({
                    method: 'JSONP',
                    url: url
                }).then(function (response) {
                    return successFn(response.data);
                }, function (response) {
                    return failureFn(response.status);
                });
            };

            InstaService.prototype.searchUser = function (user_name, successFn, failureFn) {
                var url = this.baseUrl + "search" + this.accessToken + "&q=" + user_name + this.callbackType;
                return $http({
                    method: 'JSONP',
                    url: url
                }).then(function (response) {
                    return successFn(response.data);
                }, function (response) {
                    return failureFn(response.status);
                });
            };

            InstaService.prototype.fetchFollowerIds = function (user_id,count) {
                var url = this.baseUrl + user_id + "/followed-by" + this.accessToken + this.callbackType;
                var deferredPromise = $q.defer();
                var followers = [];
                var getFollowers = function (url, cursor, deferred, callbackFn) {
                    $http({method: 'JSONP', url: url + cursor}).then(function (response) {
                        if (response.data.data) {
                            response.data.data.forEach(function (val) {
                                followers.push(val.id);
                            });
                        }
                        var next_cursor = response.data.pagination.next_cursor;
                        if (next_cursor && (!count || count > followers.length)) {
                            callbackFn(url, "&cursor=" + next_cursor, deferred, callbackFn);
                        } else {
                            deferred.resolve(followers);
                            return deferred.promise;
                        }

                    }, function (response) {
                        return deferred.reject();
                    });
                    deferred.notify();
                    return deferred.promise;
                };
                getFollowers(url, '', deferredPromise, getFollowers);
                return deferredPromise.promise;

            };

            InstaService.prototype.fetchRecentMedia = function (user_id) {
                var url = this.baseUrl + user_id + "/media/recent/" + this.accessToken + "&count=1" + this.callbackType;
                return $http({
                    method: 'JSONP',
                    url: url
                });
            };

            return InstaService;

        })();
        return new InstaService;
    }
]);
