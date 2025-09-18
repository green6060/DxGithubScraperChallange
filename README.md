# GitHub Scraper Challenge - Vercel Organization Data Collection

## Project Overview

This Rails application will collect comprehensive data from the Vercel organization on GitHub, including repositories, pull requests, reviews, and user information. The application will use the GitHub API to gather this data and store it in a database using ActiveRecord.

## Data Collection Scope

### Organizations

- **Target Organization**: Vercel
- **Data Points**: All public repositories

### Repositories

- Repository name
- Repository URL
- Privacy status (public/private)
- Archive status (active/archived)

### Pull Requests

- PR number
- PR title
- PR updated time
- PR closed time
- PR merged time
- PR author
- PR additions (lines added)
- PR deletions (lines deleted)
- PR changed files count
- PR commit count

### Reviews

- Review author
- Review state (approved, changes_requested, commented, dismissed)
- Review submission time

### Users

- GitHub login/username
- Users who opened PRs in Vercel repositories
- Users who reviewed PRs in Vercel repositories

## Technical Requirements

- **Framework**: Ruby on Rails
- **Database**: ActiveRecord ORM
- **API Integration**: GitHub REST API
- **Error Handling**: Graceful handling of rate limiting and API errors
- **Data Persistence**: PostgreSQL (recommended) or SQLite for development

## Project Tickets

### Phase 1: Project Setup & Foundation

#### Ticket 1: Rails Application Setup

- [ ] Initialize new Rails application
- [ ] Configure database (PostgreSQL for production, SQLite for development)
- [ ] Set up basic project structure
- [ ] Configure environment variables for GitHub API token
- [ ] Add necessary gems (httparty, faraday, or similar for API calls)

#### Ticket 2: Database Schema Design

- [ ] Create migration for `repositories` table
- [ ] Create migration for `pull_requests` table
- [ ] Create migration for `reviews` table
- [ ] Create migration for `users` table
- [ ] Set up proper foreign key relationships
- [ ] Add database indexes for performance

#### Ticket 3: Model Definitions

- [ ] Create `Repository` model with validations
- [ ] Create `PullRequest` model with validations
- [ ] Create `Review` model with validations
- [ ] Create `User` model with validations
- [ ] Define model associations (has_many, belongs_to)
- [ ] Add model validations and constraints

### Phase 2: GitHub API Integration

#### Ticket 4: GitHub API Service

- [ ] Create `GitHubApiService` class
- [ ] Implement authentication with GitHub API token
- [ ] Add base URL and endpoint configurations
- [ ] Implement HTTP client with proper headers
- [ ] Add request/response logging

#### Ticket 5: Rate Limiting & Error Handling

- [ ] Implement rate limiting detection and handling
- [ ] Add exponential backoff for rate limit errors
- [ ] Handle API errors gracefully (404, 403, 500, etc.)
- [ ] Add retry logic for transient failures
- [ ] Implement request queuing for rate limit compliance

#### Ticket 6: Repository Data Collection

- [ ] Implement `fetch_organization_repositories` method
- [ ] Handle pagination for large repository lists
- [ ] Parse repository data and map to model attributes
- [ ] Add data validation before saving
- [ ] Implement duplicate detection and updates

### Phase 3: Pull Request Data Collection

#### Ticket 7: Pull Request API Integration

- [ ] Implement `fetch_repository_pull_requests` method
- [ ] Handle pagination for PR lists
- [ ] Parse PR data including statistics (additions, deletions, files)
- [ ] Map PR data to model attributes
- [ ] Handle different PR states (open, closed, merged)

#### Ticket 8: PR Data Processing

- [ ] Implement PR data validation
- [ ] Add logic to handle PR updates (re-fetch existing PRs)
- [ ] Implement duplicate PR detection
- [ ] Add error handling for individual PR fetch failures
- [ ] Store PR statistics and metadata

### Phase 4: Review Data Collection

#### Ticket 9: Review API Integration

- [ ] Implement `fetch_pull_request_reviews` method
- [ ] Handle pagination for review lists
- [ ] Parse review data and states
- [ ] Map review data to model attributes
- [ ] Handle different review states

#### Ticket 10: Review Data Processing

- [ ] Implement review data validation
- [ ] Add logic to handle review updates
- [ ] Implement duplicate review detection
- [ ] Add error handling for individual review fetch failures
- [ ] Store review metadata and timestamps

### Phase 5: User Data Management

#### Ticket 11: User Data Collection

- [ ] Extract user data from PR authors
- [ ] Extract user data from review authors
- [ ] Implement user data deduplication
- [ ] Create or update user records
- [ ] Link users to their PRs and reviews

#### Ticket 12: User Data Validation

- [ ] Implement user data validation
- [ ] Handle missing or incomplete user data
- [ ] Add user data normalization
- [ ] Implement user profile updates

### Phase 6: Data Collection Orchestration

#### Ticket 13: Data Collection Service

- [ ] Create `DataCollectionService` orchestrator
- [ ] Implement collection workflow (repos → PRs → reviews → users)
- [ ] Add progress tracking and logging
- [ ] Implement collection status management
- [ ] Add collection resume capability

#### Ticket 14: Batch Processing

- [ ] Implement batch processing for large datasets
- [ ] Add progress indicators and status updates
- [ ] Implement collection scheduling
- [ ] Add data collection metrics and reporting

### Phase 7: Data Management & Utilities

#### Ticket 15: Data Cleanup & Maintenance

- [ ] Implement data cleanup utilities
- [ ] Add duplicate detection and removal
- [ ] Implement data integrity checks
- [ ] Add data export functionality

#### Ticket 16: Monitoring & Logging

- [ ] Add comprehensive logging throughout the application
- [ ] Implement error tracking and reporting
- [ ] Add performance monitoring
- [ ] Create data collection status dashboard

### Phase 8: Testing & Documentation

#### Ticket 17: Test Suite

- [ ] Write unit tests for models
- [ ] Write integration tests for API services
- [ ] Write tests for data collection workflows
- [ ] Add test fixtures and factories
- [ ] Implement test coverage reporting

#### Ticket 18: Documentation & Deployment

- [ ] Create API documentation
- [ ] Write deployment instructions
- [ ] Create data collection runbooks
- [ ] Add troubleshooting guides
- [ ] Document configuration options

## Database Schema Overview

### Repositories Table

```sql
- id (primary key)
- github_id (unique)
- name
- url
- is_private (boolean)
- is_archived (boolean)
- created_at
- updated_at
```

### Pull Requests Table

```sql
- id (primary key)
- repository_id (foreign key)
- github_id (unique)
- number
- title
- author_id (foreign key to users)
- updated_at
- closed_at
- merged_at
- additions (integer)
- deletions (integer)
- changed_files (integer)
- commit_count (integer)
- created_at
- updated_at
```

### Reviews Table

```sql
- id (primary key)
- pull_request_id (foreign key)
- github_id (unique)
- reviewer_id (foreign key to users)
- state (enum: approved, changes_requested, commented, dismissed)
- submitted_at
- created_at
- updated_at
```

### Users Table

```sql
- id (primary key)
- github_id (unique)
- login (username)
- created_at
- updated_at
```

## API Endpoints to Utilize

- `GET /orgs/{org}/repos` - List organization repositories
- `GET /repos/{owner}/{repo}/pulls` - List pull requests for a repository
- `GET /repos/{owner}/{repo}/pulls/{pull_number}/reviews` - List reviews for a pull request
- `GET /user` - Get authenticated user information

## Rate Limiting Considerations

- GitHub API allows 5,000 requests per hour for authenticated requests
- Implement exponential backoff for rate limit errors
- Use conditional requests (ETags) to reduce API calls
- Implement request queuing to stay within rate limits

## Error Handling Strategy

- Graceful degradation for API failures
- Retry logic for transient errors
- Comprehensive logging for debugging
- Data validation before persistence
- Rollback capabilities for failed operations

## Success Criteria

- [ ] Successfully collect all public repositories from Vercel organization
- [ ] Collect all pull requests for each repository
- [ ] Collect all reviews for each pull request
- [ ] Collect all users who authored PRs or reviews
- [ ] Handle rate limiting gracefully
- [ ] Maintain data integrity throughout the collection process
- [ ] Provide comprehensive error handling and logging
- [ ] Deliver a maintainable and well-tested codebase

---

**Note**: This project will be implemented in phases, with each ticket representing a discrete, testable unit of work. The tickets are designed to build upon each other, ensuring a solid foundation before moving to more complex features.
