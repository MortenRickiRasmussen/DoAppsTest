FROM mcr.microsoft.com/dotnet/sdk:5.0-alpine AS build

WORKDIR /source

RUN apk update \                                                                                                                                                                                                                        
  && apk add ca-certificates wget \                                                                                                                                                                                                      
  && update-ca-certificates

# Cache config, csproj and sln
#COPY ./NuGet.config ./
COPY *.csproj ./

# Restore packages
RUN dotnet restore

# Copy everything else and build
COPY . ./

RUN dotnet publish -c Release -o /output

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:5.0-alpine as runtime
WORKDIR /app

# Install deps
RUN apk update \                                                                                                                                                                                                                        
    && apk add --no-cache ca-certificates wget icu-libs \                                                                                                                                                                                                      
    && update-ca-certificates
    
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false

# Standard Environment variables
ENV ASPNETCORE_URLS=http://*:3000

# Copy build output to container
COPY --from=build /output .

ENV RUNPATH=DoAppsTest.dll

# Set user to nobody
RUN chown nobody:nogroup -R .
USER nobody

ENTRYPOINT dotnet $RUNPATH