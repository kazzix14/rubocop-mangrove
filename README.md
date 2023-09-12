```
git config core.hooksPath hooks
bundle exec rspec -f d
bundle exec rubocop -DESP
bundle exec srb typecheck
bundle exec ordinare --check
bundle exec ruboclean
bundle exec yardoc -o docs/ --plugin yard-sorbet
rake build
rake release
```

