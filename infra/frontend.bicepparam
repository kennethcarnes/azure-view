using './frontend.bicep'

param swaName = ''
param location = 'westus2'
param swaSku = 'Free'
param repositoryUrl = 'https://www.github.com/kennethcarnes/azure-view'
param branch = 'main'
param repositoryToken = ''
param appLocation = '/'
param apiLocation = 'api'
param appArtifactLocation = ''

