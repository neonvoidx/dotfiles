from typing import List
from kitty.boss import Boss

def main(Args: List[str]) -> str:
    new_title = input("Enter new tab title: ")
    return new_title

def handle_result(args: List[str], new_title: str, target_window_id: int, boss: Boss) -> None:
    w = boss.window_id_map.get(target_window_id)
    if w is not None:
        if new_title is not None and new_title != w.title and new_title !="":
            boss.call_remote_control(w, ('set-tab-title', f'--match=id:{w.id}', new_title))
