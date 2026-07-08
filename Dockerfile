# ---- build the Svelte client -> server/wwwroot ----
FROM node:20-slim AS client
WORKDIR /src/client
COPY client/package*.json ./
RUN npm install --no-audit --no-fund
COPY client/ ./
RUN npm run build   # vite outputs to ../server/wwwroot

# ---- build & publish the .NET server ----
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS server
WORKDIR /src
COPY server/ ./server/
# Bring in the freshly built SPA assets.
COPY --from=client /src/server/wwwroot ./server/wwwroot
RUN dotnet publish server/Anticode.Server.csproj -c Release -o /app/publish

# ---- runtime ----
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=server /app/publish ./

# Persist the SQLite database outside the container.
ENV DATABASE_PATH=/data/assessment.db
ENV ASPNETCORE_URLS=http://0.0.0.0:8080
VOLUME ["/data"]
EXPOSE 8080

# APP_PASSWORD must be provided at run time, e.g.:
#   docker run -e APP_PASSWORD=... -v anticode:/data -p 8080:8080 anticode
ENTRYPOINT ["dotnet", "Anticode.Server.dll"]
